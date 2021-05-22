local Deque = require("user.deque").Deque

local function git_head_hash(pack)
	return vim.fn.system([[git -C "]]..pack.install_path..[[" rev-parse HEAD]])
end

local PackMan = {}

function PackMan:new(args)
	args = args or {}
	local packman = {
		path = vim.fn.expand(args.path) or vim.fn.stdpath("data").."/site/pack/user/",

		packs = {},

		config_queue = Deque:new(),
		config_done = {},
	}
	self.__index = self
	setmetatable(packman, self)
	return packman
end

function PackMan:install(pack)
	if vim.fn.isdirectory(pack.install_path) > 0 then
		return
	end

	local command = "git clone --depth 1 --recurse-submodules "
	if pack.branch then
		command = command.."--branch "..vim.fn.fnameescape(pack.branch).." "
	end
	command = command..vim.fn.fnameescape(pack.repo).." "..vim.fn.fnameescape(pack.install_path)

	pack.job = io.popen(command, "r")
	pack.newly_installed = true
end

function PackMan:request(pack)
	if self.packs[pack.name] then
		error(pack.name.." is requested more than once")
	end
	self.packs[pack.name] = pack

	if pack.init then pack.init() end

	local install_path = pack.name
	if pack.branch then
		install_path = install_path.."/branch/"..pack.branch
	else
		install_path = install_path.."/default/default"
	end
	local packadd_path = install_path
	if pack.subdir then packadd_path = packadd_path.."/"..pack.subdir end
	pack.packadd_path = packadd_path
	pack.install_path = self.path.."/opt/"..install_path

	self:install(pack)
	self.config_queue:push_back(pack)
end

function PackMan:await_jobs()
	for _, pack in pairs(self.packs) do
		if pack.job then
			pack.job:close()
			vim.api.nvim_command("silent! helptags "..vim.fn.fnameescape(pack.install_path).."/doc")
			pack.job = nil

			if pack.newly_installed and pack.install then
				pack.install()
			end

			local hash = git_head_hash(pack)
			if pack.hash and pack.hash ~= hash then
				if pack.update then pack.update() end
				pack.hash = hash
			end
		end
	end
end

function PackMan:config(pack)
	vim.api.nvim_command("packadd "..vim.fn.fnameescape(pack.packadd_path))

	-- work around vim#1994
	if vim.v.vim_did_enter > 0 then
		for after_source in vim.fn.glob(pack.install_path.."/after/plugin/**/*.vim"):gmatch("[^\n]+") do
			vim.api.nvim_command("source "..vim.fn.fnameescape(after_source))
		end
	end

	if pack.config then pack.config() end

	self.config_done[pack.name] = true
end

function PackMan:can_config(pack)
	if pack.after then
		for _, after in ipairs(pack.after) do
			if not self.config_done[after] then return false end
		end
	end
	return true
end

function PackMan:do_config_queue()
	local counter = 0

	while (self.config_queue:len() > 0) and (counter < self.config_queue:len())  do
		local pack = self.config_queue:pop_front()

		if self:can_config(pack) then
			self:config(pack)
			counter = 0
		else
			self.config_queue:push_back(pack)
			counter = counter + 1
		end
	end
end

function PackMan:update()
	for _, pack in pairs(self.packs) do
		pack.hash = git_head_hash(pack)
		pack.job = io.popen("git -C "..vim.fn.fnameescape(pack.install_path).." pull", "r")
	end
end

return { PackMan = PackMan }

local Deque = require("user.deque").Deque
local escapist = require("user.escapist")

local PackMan = {}

function PackMan:new(args)
	args = args or {}
	local packman = {
		path = args.path or vim.fn.resolve(vim.fn.stdpath("data").."/site/pack/user/"),

		packs = {},

		config_queue = Deque:new(),
		config_done = {},
	}
	self.__index = self
	setmetatable(packman, self)
	return packman
end

function PackMan:install(pack)
	if vim.fn.empty(vim.fn.glob(pack.install_path)) == 0 then
		return
	end

	local command = "git clone --depth 1 --recurse-submodules "
	if pack.branch then
		command = command..[[--branch ']]..pack.branch..[[' ]]
	end
	command = command..[[']]..pack.repo..[[' ']]..pack.install_path..[[']]

	pack.job = io.popen(command, "r")
end

function PackMan:request(pack)
	if self.packs[pack.name] then
		error(pack.name.." is requested more than once")
	end
	self.packs[pack.name] = pack

	if pack.init then pack.init() end

	local packadd_path = pack.name
	if pack.branch then
		packadd_path = packadd_path.."/branch/"..escapist.escape(pack.branch)
	else
		packadd_path = packadd_path.."/default/default"
	end
	pack.packadd_path = vim.fn.resolve(packadd_path)
	pack.install_path = vim.fn.resolve(self.path.."/opt/"..pack.packadd_path)

	self:install(pack)

	self.config_queue:push_back(pack)
end

function PackMan:await_jobs()
	for _, pack in pairs(self.packs) do
		if pack.job then
			pack.job:close()
			vim.api.nvim_command("silent! helptags "..pack.install_path.."/doc")
			pack.job = nil
		end
	end
end

function PackMan:config(pack)
	vim.api.nvim_command("packadd "..pack.packadd_path)

	-- work around vim#1994
	if vim.v.vim_did_enter > 0 then
		for after_source in vim.fn.glob(pack.install_path.."/after/plugin/**/*.vim"):gmatch("[^\n]+") do
			vim.api.nvim_command("source "..after_source)
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
	for name, pack in pairs(self.packs) do
		pack.job = io.popen([[git -C ']]..pack.install_path..[[' pull]], "r")
	end
end

function PackMan:clean()
	local paths = {}

	for path in vim.fn.glob(vim.fn.resolve(self.path.."/opt/*/*/*/*")):gmatch("[^\n]+") do
		paths[path] = true
	end
	for _, pack in pairs(self.packs) do
		paths[pack.install_path] = false
	end

	for path, should_remove in pairs(paths) do
		if should_remove then
			os.execute("rm -rf "..path)
		end
	end
end

return { PackMan = PackMan }

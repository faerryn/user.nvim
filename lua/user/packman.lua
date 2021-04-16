local Deque = require("user.deque").Deque

local PackMan = {}

function PackMan:new(args)
	args = args or {}
	local packman = {
		path = args.path or vim.fn.resolve(vim.fn.stdpath("data").."/site/pack/user/"),

		command_install = args.command_install or "git clone --depth 1 --recurse-submodules",
		command_update = args.command_update or "git pull --rebase",
		command_clean = args.command_clean or "rm -rf",

		packs = {},

		config_queue = Deque:new(),
		config_done = {},

		jobs = Deque:new(),
	}
	self.__index = self
	setmetatable(packman, self)
	return packman
end

function PackMan:request(pack)
	self.packs[pack.name] = pack

	if pack.init then pack.init() end

	pack.install_path = vim.fn.resolve(self.path.."/opt/"..vim.fn.fnameescape(pack.name))

	if vim.fn.empty(vim.fn.glob(pack.install_path)) > 0 then
		self.jobs:push_back(io.popen(self.command_install..[[ ']]..pack.source..[[' ']]..pack.install_path..[[']], "r"))
	end

	self.config_queue:push_back(pack)
end

function PackMan:await()
	while self.jobs:len() > 0 do
		self.jobs:pop_back():close()
	end
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

			vim.api.nvim_command("packadd "..pack.name)
			if pack.config then pack.config() end

			self.config_done[pack.name] = true
			counter = 0
		else
			self.config_queue:push_back(pack)
			counter = counter + 1
		end
	end
end

function PackMan:update()
	for name, pack in pairs(self.packs) do
		self.jobs:push_back(io.popen([[git -C ']]..pack.install_path..[[' pull]], "r"))
	end
	while self.jobs:len() > 0 do
		self.jobs:pop_back():close()
	end
end

function PackMan:clean()
	local paths = {}

	for path in vim.fn.glob(vim.fn.resolve(self.path.."/*/*")):gmatch("[^\n]+") do
		paths[path] = true
	end
	for _, pack in pairs(self.packs) do
		paths[pack.install_path] = false
	end

	for path, should_remove in pairs(paths) do
		if should_remove then
			os.execute(self.command_clean.." "..path)
		end
	end
end

return { PackMan = PackMan }

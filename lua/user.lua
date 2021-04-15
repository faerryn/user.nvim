local packs = {}
local packs_install_path = vim.fn.stdpath"data".."/site/pack/user/opt/"

local packqueue = require'user.packqueue'.PackQueue:new()
local jobs = require'user.deque'.Deque:new()

local function parse_use(args)
	local pack = {}

	if type(args) == "string" then
		pack.short_url = args
	elseif type(args) == "table" then
		pack.short_url = args[1]

		pack.init = args.init
		pack.config = args.config

		pack.disabled = args.disabled

		if type(args.after) == "string" then
			pack.after = { args.after }
		else
			pack.after = args.after
		end
	else
		error("user.user -- invalid args")
	end

	pack.url = "https://github.com/"..pack.short_url..".git"

	local match = pack.short_url:gmatch("[^/]+")
	pack.author = match()
	pack.name = match()
	pack.short_install_path = pack.author.."-"..pack.name
	pack.install_path = packs_install_path..pack.short_install_path

	return pack
end

local function use(args)
	local pack = parse_use(args)
	if pack.disabled then return end
	packs[pack.short_url] = pack
	if pack.init then pack.init() end

	if vim.fn.empty(vim.fn.glob(pack.install_path)) > 0 then
		jobs:push_back(io.popen([[git clone --depth 1 --recurse-submodules ']]..pack.url..[[' ']]..pack.install_path..[[']], "r"))
		if vim.v.vim_did_enter > 0 then
			pack.jobs:pop_back():close()
		end
	end

	packqueue:enqueue(pack)

	if vim.v.vim_did_enter > 0 then
		packqueue:doqueue()
	end
end

local function update()
	for _, pack in pairs(packs) do
		jobs:push_back(io.popen([[git -C ']]..pack.install_path..[[' pull]], "r"))
	end
	while jobs:__len() > 0 do
		jobs:pop_back():close()
	end
end

local function clean()
	local paths = {}

	for path in vim.fn.glob(vim.fn.resolve(packs_install_path.."/*")):gmatch("[^\n]+") do
		paths[path] = true
	end
	for _, pack in pairs(packs) do
		paths[pack.install_path] = false
	end

	for path, to_remove in pairs(paths) do
		if to_remove then
			os.execute("rm -rf "..path)
		end
	end
end

local function setup()
	if vim.v.vim_did_enter > 0 then
		while jobs:__len() > 0 do
			jobs:pop_back():close()
		end
		packqueue:doqueue()
	else
		vim.api.nvim_command([[autocmd VimEnter * ++once lua require("user").setup()]])
	end
end

return {
	setup = setup,

	use = use,

	update = update,
	clean = clean,
}

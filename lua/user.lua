local packman

local function use(args)
	local pack = {}

	if type(args) == "string" then
		pack.name = args
	elseif type(args) == "table" then
		if args.disabled then
			return
		end

		pack.name = args[1]

		pack.init = args.init
		pack.config = args.config

		if type(args.after) == "string" then
			pack.after = { args.after }
		else
			pack.after = args.after
		end
	else
		error("user.user -- invalid args")
	end

	pack.source = "https://github.com/"..pack.name..".git"

	packman:request(pack)
end

local function setup(args)
	packman = require'user.packman'.PackMan:new(args)
	vim.api.nvim_command([[autocmd VimEnter * ++once lua require("user").startup()]])
end

local function startup()
	packman:await()
	packman:do_config_queue()
end

local function update()
	packman:update()
end

local function clean()
	packman:clean()
end

return {
	setup = setup,
	startup = startup,

	use = use,

	update = update,
	clean = clean,
}

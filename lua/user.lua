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

		pack.repo = args.repo
		pack.branch = args.branch

		pack.subdir = args.subdir

		pack.init = args.init
		pack.config = args.config

		pack.install = args.install
		pack.update = args.update

		if type(args.after) == "string" then
			pack.after = { args.after }
		else
			pack.after = args.after
		end
	else
		error("user.use -- invalid args")
	end

	pack.repo = pack.repo or "https://github.com/"..pack.name..".git"

	packman:request(pack)
end

local function setup(args)
	if args and args.path then args.path = vim.fn.expand(args.path) end
	packman = require'user.packman'.PackMan:new(args)
end

local function flush()
	packman:await_jobs()
	packman:do_config_queue()
end

local function update()
	packman:update()
	packman:await_jobs()
end

return {
	flush = flush,
	setup = setup,
	update = update,
	use = use,

	startup = flush,
}

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

  if packman.packs[pack.name] then
    return packman.packs[pack.name]
  end

  if pack.repo or string.match(pack.name, "^[^/]+/[^/]+$") then
    pack.repo = pack.repo or "https://github.com/"..pack.name..".git"
    return packman:request(pack)
  end

  local path = vim.fn.fnamemodify(pack.name, ":p")
  if vim.fn.isdirectory(path) then
    vim.opt.runtimepath:prepend(path)
  else
    error("user.user -- invalid args")
  end
  return pack
end

local function setup(args)
  if args and args.path then args.path = vim.fn.expand(args.path) end
  packman = require'user.packman'.PackMan:new(args)
end

local function flush()
  if packman.parallel then
    packman:await_jobs()
    packman:do_config_queue()
  end
end

local function update()
  packman:update()
  if packman.parallel then
    packman:await_jobs()
  end
end

return {
  setup = setup,
  update = update,
  use = use,

  flush = flush,
  startup = flush,
}

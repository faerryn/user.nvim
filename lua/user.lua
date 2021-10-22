local packman

--[[
-- This is the fontend to packman.use()
-- It fills out all the arguments and figures out if the user is just
-- requesting an runtimepath edit.
--]]
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
    pack.pin = args.pin

    pack.subdir = args.subdir

    pack.init = args.init
    pack.config = args.config

    pack.install = args.install
    pack.update = args.update

    pack.after = args.after
  else
    error("user.use -- invalid args")
  end

  if packman.packs[pack.name] then
    return packman.packs[pack.name]
  end

  -- we have a repo that can be managed by packman
  if pack.repo or string.match(pack.name, "^[^/]+/[^/]+$") then
    pack.repo = pack.repo or "https://github.com/"..pack.name..".git"
    return packman:request(pack)
  end

  -- we can install local directories too!
  local path = vim.fn.fnamemodify(pack.name, ":p")
  if vim.fn.isdirectory(path) then
    vim.opt.runtimepath:prepend(path)
  else
    error("user.user -- invalid args")
  end
  return pack
end

--[[
-- instantiate everything
--]]
local function setup(args)
  if args and args.path then
    args.path = vim.fn.expand(args.path)
  end
  packman = require("user.packman").PackMan:new(args)
end

--[[
-- flush parallel git clone jobs
-- does nothing if parallel jobs are not enabled
--]]
local function flush()
  if packman.parallel then
    packman:flush_jobs()
    packman:flush_packadd_queue()
  end
end

--[[
-- updates packages
-- awaits parallel git pull jobs if enabled
--]]
local function update()
  packman:update_all()
  if packman.parallel then
    packman:flush_jobs()
  end
end

return {
  setup = setup,
  update = update,
  use = use,

  flush = flush,
  startup = flush,
}

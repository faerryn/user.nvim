local Deque = require("user.deque").Deque

local function gen_helptags(pack)
  vim.api.nvim_command("silent! helptags "..vim.fn.fnameescape(pack.install_path).."/doc")
end

local function git_head_hash(pack)
  return vim.fn.system([[git -C "]]..pack.install_path..[[" rev-parse HEAD]])
end

local function packadd(pack)
  vim.api.nvim_command("packadd "..vim.fn.fnameescape(pack.packadd_path))
  -- work around vim#1994
  if vim.v.vim_did_enter == 1 then
    for after_source in vim.fn.glob(pack.install_path.."/after/plugin/**/*.vim"):gmatch("[^\n]+") do
      vim.api.nvim_command("source "..vim.fn.fnameescape(after_source))
    end
  end
end

local function chdir_do_fun(dir, fun)
  local cwd = vim.loop.cwd()
  vim.loop.chdir(dir)
  pcall(fun)
  vim.loop.chdir(cwd)
end

local function post_install(pack)
  if pack.pin then
    local escaped_install_path = vim.fn.shellescape(pack.install_path)
    os.execute("git -C "..escaped_install_path.." checkout --quiet "..pack.pin)
  end
  gen_helptags(pack)
  if pack.install then
    chdir_do_fun(pack.install_path, pack.install)
  end
end

local function post_update(pack)
  local hash = git_head_hash(pack)
  if pack.hash and pack.hash ~= hash then
    gen_helptags(pack)
    if pack.update then
      chdir_do_fun(pack.install_path, pack.update)
    end
    pack.hash = hash
  end
end

local PackMan = {}

function PackMan:new(args)
  args = args or {}
  local packman = {
    path = (args.path and vim.fn.resolve(vim.fn.fnamemodify(args.path, ":p"))) or vim.fn.stdpath("data").."/site/pack/user/",

    packs = {},

    packadd_queue = Deque:new(),

    parallel = args.parallel or false,
  }
  self.__index = self
  setmetatable(packman, self)
  return packman
end

function PackMan:install(pack)
  if vim.fn.isdirectory(pack.install_path) == 1 then
    return
  end

  local command = "git clone --quiet --recurse-submodules --shallow-submodules "

  if not pack.pin then
    command = command.."--depth 1 "
  end

  if pack.branch then
    command = command.."--branch "..vim.fn.shellescape(pack.branch).." "
  end

  local escaped_install_path = vim.fn.shellescape(pack.install_path)
  command = command..vim.fn.shellescape(pack.repo).." "..escaped_install_path

  if self.parallel then
    pack.install_job = io.popen(command, "r")
  else
    os.execute(command)
    post_install(pack)
  end
end

function PackMan:update(pack)
  if not pack.pin then
    pack.hash = git_head_hash(pack)

    local escaped_install_path = vim.fn.shellescape(pack.install_path)
    local command = "git -C "..escaped_install_path.." pull --quiet --recurse-submodules --update-shallow"

    if self.parallel then
      pack.update_job = io.popen(command, "r")
    else
      os.execute(command)
      post_update(pack)
    end
  end
end

function PackMan:request(pack)
  if self.packs[pack.name] then
    return self.packs[pack.name]
  end
  self.packs[pack.name] = pack

  if pack.init then pack.init() end

  local install_path = pack.name
  if pack.branch then
    install_path = install_path.."/branch/"..pack.branch
  else
    install_path = install_path.."/default/default"
  end
  if pack.pin then
    install_path = install_path.."/commit/"..pack.pin
  else
    install_path = install_path.."/default/default"
  end

  local packadd_path = install_path
  if pack.subdir then packadd_path = packadd_path.."/"..pack.subdir end

  pack.packadd_path = packadd_path
  pack.install_path = self.path.."/opt/"..install_path

  self:install(pack)
  if self.parallel then
    self.packadd_queue:push_back(pack)
  else
    packadd(pack)
    if pack.config then pack.config() end
  end

  return pack
end

function PackMan:flush_jobs()
  for _, pack in pairs(self.packs) do
    if pack.install_job then
      pack.install_job:close()
      pack.install_job = nil
      post_install(pack)
    end
    if pack.update_job then
      pack.update_job:close()
      pack.update_job = nil
      post_update(pack)
    end
  end
end

function PackMan:flush_packadd_queue()
  while self.packadd_queue:len() > 0 do
    local pack = self.packadd_queue:pop_front()
    packadd(pack)
    if pack.config then pack.config() end
  end
end

function PackMan:update_all()
  for _, pack in pairs(self.packs) do
    self:update(pack)
  end
end

return { PackMan = PackMan }

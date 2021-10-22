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

    config_queue = Deque:new(),
    config_done = {},

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

  local command = "git clone --quiet --recurse-submodules "

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
    self.config_queue:push_back(pack)
  else
    post_install(pack)
    packadd(pack)
    if pack.config then pack.config() end
  end

  return pack
end

function PackMan:await_jobs()
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

function PackMan:config(pack)
  packadd(pack)

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

  while (self.config_queue:len() == 1) and (counter < self.config_queue:len())  do
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
    if not pack.pin then
      pack.hash = git_head_hash(pack)

      local escaped_install_path = vim.fn.shellescape(pack.install_path)
      local command = "git -C "..escaped_install_path.." pull --quiet"

      if self.parallel then
        pack.update_job = io.popen(command, "r")
      else
        os.execute(command)
        post_update(pack)
      end
    end
  end
end

return { PackMan = PackMan }

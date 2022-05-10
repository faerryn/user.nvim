local Deque = require("user.deque").Deque

local function gen_helptags(pack)
    vim.cmd(("silent! helptags %s/doc"):format(vim.fn.fnameescape(pack.install_path)))
end

local function git_head_hash(pack)
    return vim.fn.system(("git -C %s rev-parse HEAD"):format(vim.fn.shellescape(pack.install_path)))
end

local function packadd(pack)
    vim.cmd(("packadd %s"):format(vim.fn.fnameescape(pack.packadd_path)))
    -- work around vim#1994
    if vim.v.vim_did_enter == 1 then
        for after_source in vim.fn.glob(pack.install_path .. "/after/plugin/**/*.vim"):gmatch "[^\n]+" do
            vim.cmd(("source %s"):format(vim.fn.fnameescape(after_source)))
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
        os.execute(("git -C %s checkout --quiet %s"):format(escaped_install_path, pack.pin))
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
        path = (args.path and vim.fn.resolve(vim.fn.fnamemodify(args.path, ":p")))
            or (vim.fn.stdpath "data") .. "/site/pack/user/",

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

    local command = ("git clone --quiet --recurse-submodules --shallow-submodules %s %s %s %s"):format(
        (pack.pin and "" or "--depth 1"),
        (pack.branch and "--branch " .. vim.fn.shellescape(pack.branch) or ""),
        vim.fn.shellescape(pack.repo),
        vim.fn.shellescape(pack.install_path)
    )

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
        local command = ("git -C %s pull --quiet --recurse-submodules --update-shallow"):format(escaped_install_path)

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

    if pack.init then
        pack.init()
    end

    local install_path = ("%s%s%s"):format(
        pack.name:gsub("/", "_"),
        pack.branch and ("/branch/" .. pack.branch) or "/default/default",
        pack.pin and ("/commit/" .. pack.pin) or "/default/default"
    )

    local packadd_path = install_path
    if pack.subdir then
        packadd_path = packadd_path .. "/" .. pack.subdir
    end

    pack.packadd_path = packadd_path
    pack.install_path = self.path .. "/opt/" .. install_path

    self:install(pack)
    if self.parallel then
        self.packadd_queue:push_back(pack)
    else
        packadd(pack)
        if pack.config then
            pack.config()
        end
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
        if pack.config then
            pack.config()
        end
    end
end

function PackMan:update_all()
    for _, pack in pairs(self.packs) do
        self:update(pack)
    end
end

function PackMan:clean()
    local keep = {}
    for _, pack in pairs(self.packs) do
        keep[vim.fn.resolve(pack.install_path)] = true
    end
    for place in vim.fn.expand(vim.fn.stdpath "data" .. "/site/pack/user/opt/*/*/*/*/*"):gmatch "[^\n]+" do
        if not keep[place] then
            vim.fn.delete(place, "rf")
        end
    end
end

return { PackMan = PackMan }

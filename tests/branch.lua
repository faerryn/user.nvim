--
-- Test the 'branch' option
--

vim.o.rtp = ".,"..vim.o.rtp
vim.o.pp = ".,"..vim.o.pp

local user = require("user")
user.setup({ path = "./pack/user" })
local use = user.use

use {
  "gruvbox-community/gruvbox",
  config = function()
    vim.api.nvim_command("colorscheme gruvbox")
    print("gruvbox")
  end,
}

user.flush()

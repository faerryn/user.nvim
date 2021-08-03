-- Bootstrapping
local user_install_path = vim.fn.stdpath("data").."/site/pack/user/opt/faerryn/user.nvim/default/default"
if vim.fn.empty(vim.fn.glob(user_install_path)) > 0 then
  os.execute([[git clone --depth 1 https://github.com/faerryn/user.nvim.git "]]..user_install_path..[["]])
end
vim.api.nvim_command("packadd faerryn/user.nvim/default/default")

local user = require("user")
user.setup()
local use = user.use

-- user.nvim needs to manage itself!
use "faerryn/user.nvim"

-- Gruvbox is mandatory
use {
  "gruvbox-community/gruvbox",
  config = function()
    vim.api.nvim_command("colorscheme gruvbox")
  end,
}

-- gitsigns.nvim requires plenary.nvim, but plenary.nvim's declaration is 
use {
  "lewis6991/gitsigns.nvim",
  after = "nvim-lua/plenary.nvim",
  config = function()
    require("gitsigns").setup()
  end,
}

use "nvim-lua/plenary.nvim"

user.flush()

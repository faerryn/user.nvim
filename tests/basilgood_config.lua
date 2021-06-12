--
-- Test basilgood's config.
--

vim.o.rtp = ".,"..vim.o.rtp
vim.o.pp = ".,"..vim.o.pp

local user = require("user")
user.setup({ path = "./pack/user" })
local use = user.use

vim.o.swapfile = false
vim.o.undofile = true
vim.bo.swapfile = false
vim.bo.undofile = true
vim.wo.number = true
vim.o.mouse = 'a'
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.bo.tabstop = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab = true
vim.o.list = true
vim.wo.list = true
vim.o.completeopt = "menuone,noinsert"
vim.o.confirm = true
vim.o.hidden = true
vim.o.inccommand = "nosplit"

use "tpope/vim-vinegar"
use {
  "hrsh7th/nvim-compe",
  config = function()
    require'compe'.setup {
      enabled = true;
      autocomplete = true;
      debug = false;
      min_length = 1;
      preselect = 'disable';
      throttle_time = 80;
      source_timeout = 200;
      incomplete_delay = 400;
      max_abbr_width = 100;
      max_kind_width = 100;
      max_menu_width = 100;
      documentation = true;
      source = {
        path = true;
        buffer = true;
      };
    }
  end
}

user.flush()

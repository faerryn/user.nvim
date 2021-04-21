--
-- Test the 'onehalf' plugin.
--

vim.o.rtp = ".,"..vim.o.rtp
vim.o.pp = ".,"..vim.o.pp

local user = require'user'
user.setup({ path = './pack/user' })
local use = user.use

use {
	"sonph/onehalf",
	subdir = "vim",
	config = function()
		vim.api.nvim_command("colorscheme onehalfdark")
	end,
}

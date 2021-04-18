--
-- Test the 'branch' option
--

vim.o.rtp = ".,"..vim.o.rtp

local user = require'user'
user.setup()
local use = user.use

use {
	"gruvbox-community/gruvbox",
	config = function()
		vim.api.nvim_command("colorscheme gruvbox")
		print("gruvbox")
	end,
}

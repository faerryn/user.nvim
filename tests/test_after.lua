--
-- Test the 'after' option
--

vim.o.rtp = ".,"..vim.o.rtp

local user = require'user'
user.setup()
local use = user.use

use {
	"gruvbox-community/gruvbox",
	after = "norcalli/nvim.lua",
	config = function()
		vim.api.nvim_command("colorscheme gruvbox")
		print("gruvbox")
	end,
}

use {
	"norcalli/nvim.lua",
	config = function()
		print("nvim.lua")
	end,
}

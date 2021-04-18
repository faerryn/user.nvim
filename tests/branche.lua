--
-- Test the 'after' option.
--

vim.o.rtp = ".,"..vim.o.rtp

local user = require'user'
user.setup()
local use = user.use

use {
	"nvim-treesitter/nvim-treesitter",
	branch = "update-lockfile-pr",
	config = function()
		require'nvim-treesitter.configs'.setup {
			highlight = { enable = true },
		}
	end,
}

use {
	"gruvbox-community/gruvbox",
	config = function()
		vim.api.nvim_command("colorscheme gruvbox")
	end,
}

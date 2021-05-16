""
"" Test the 'onehalf' plugin.
""

let &rtp = ".,"..&rtp
let &pp = ".,"..&pp

lua << EOF
local user = require("user")
user.setup({ path = "./pack/user" })
local use = user.use

use {
	"sonph/onehalf",
	subdir = "vim",
	install = function()
		print("installed")
	end,
	update = function()
		print("updated")
	end,
	config = function()
		vim.api.nvim_command("colorscheme onehalfdark")
	end,
}
EOF

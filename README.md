# USER.NVIM
Since the advent of vim and neovim, countless package managers have appeared and dissappeared. Well, here's another one, inspired by Emacs' straight.el and use-package

## Philosophy
Configurations should be reproducible and require minimal user effort.
With `user.nvim`, there is no need to run something like `:PlugInstall`. Once your config file is written, you are done!

**NOTE:** You still need to run `require("user").update()` from time to time. Updates are not necesssary for getting your config up and running, and aren't handled automatically.

## Requirements
- [Neovim 0.5.0](https://neovim.io/)
- [Git](https://git-scm.com/)

## Recommendations
Neovim 0.5.0 now supports using init.lua, where lua code can be put.
If you have a init.vim or .vimrc, you can put your lua code in a heredoc block:

```
lua << EOF
-- lua code goes here
EOF
```

## Usage
setup(): mandatory to make the lua work
```lua
local user = require("user")
user.setup()
local use = user.user
```

use {...}: manage your packages
```lua
use {
	"package_author/package_name",
	disabled = false, -- if true, ignored this use call.
	repo = nil, -- if non-nil, then clone from this repo instead
	branch = nil, -- if non-nil, then clone from this branch instead of default branch
	subdir = nil, -- if non-nil, then will add that subdirectory to rtp
	after = {}, -- list of dependencies, run config() only after these have been loaded
	init = function()
		-- will run immediately unless disabled = true.
	end,
	config = function()
		-- will run after the package is loaded.
	end,
}
```

flush(): call after all `use` calls
```lua
user.flush()
```

update(): update your packages
```lua
require("user").update()
```

## Bootstrap user.nvim
```lua
local user_install_path = vim.fn.stdpath("data").."/site/pack/user/opt/faerryn/user.nvim/default/default"
if vim.fn.isdirectory(user_install_path) == 0 then
	os.execute([[git clone --quiet --depth 1 https://github.com/faerryn/user.nvim.git "]]..user_install_path..[["]])
end
vim.api.nvim_command("packadd faerryn/user.nvim/default/default")
```

## Example
```lua
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

user.flush() -- don't forget to flush all queued config()s!
```

# News and FAQ
## The last update broke everything!
That's terrible! I probably introduced a breaking change. Try these steps.
- If you use [bootstrapping](#bootstrap-usernvim), replace your old bootstrapping code with the most recent bit.
- Then, delete `user.nvim`'s plugins directory with `rm -r ~/.local/share/nvim/site/pack/user/`.
- If it doesn't work, please file an issue!
## Packages are installing, but my config()s aren't loading!
Make sure you have `use.flush()` after all your use calls. `use.flush()` is meant to handle dependency chains and the like.

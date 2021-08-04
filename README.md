# USER.NVIM
Since the advent of vim and neovim, countless package managers have appeared and dissappeared.
Well, here's another one, inspired by Emacs' straight.el and use-package

## Philosophy
Configurations should be reproducible and require minimal user effort.
With `user.nvim`, there is no need to run something like `:PlugInstall`.
Once your config file is written, you are done!

**NOTE:** You still need to run `require("user").update()` from time to time.

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
setup(): Mandatory to make the lua work:
```lua
local user = require("user")
user.setup()
local use = user.user
```

If you want to enable parallel git operations:
```lua
user.setup({ parallel = true })
```
Note that you still have to wait for the operations to complete.

use {...}: Install a package from github or other git repositories.
```lua
use {
	"package_author/package_name",
	repo = nil, -- if non-nil, then clone from this repo instead
	branch = nil, -- if non-nil, then clone from this branch instead of default branch
	subdir = nil, -- if non-nil, then will add that subdirectory to rtp
	init = function()
		-- will run immediately unless disabled = true.
	end,
	config = function()
		-- will run after the package is loaded. not very useful if you don't have `parallel` enabled.
	end,
}
```

flush(): If `parallel` is enabled, then this will wait until all git operations are done and run your `config()`s.
Put this at the end of your configuration.
```lua
user.flush()
```

update(): update your packages
```lua
require("user").update()
```

## Bootstrap user.nvim
```lua
local user_packadd_path = "faerryn/user.nvim/default"
local user_install_path = vim.fn.stdpath("data").."/site/pack/user/opt/"..user_packadd_path
if vim.fn.isdirectory(user_install_path) == 0 then
  os.execute("git clone --quiet --depth 1 https://github.com/faerryn/user.nvim.git "..vim.fn.shellescape(user_install_path))
end
vim.api.nvim_command("packadd "..vim.fn.fnameescape(user_packadd_path))
```

## Example
```lua
local user = require("user")
user.setup()
local use = user.use

-- user.nvim can manage itself!
use "faerryn/user.nvim"

-- Gruvbox is mandatory
use "gruvbox-community/gruvbox"
vim.api.nvim_command("colorscheme gruvbox")

-- Gitsigns are fun
use "nvim-lua/plenary.nvim"
use "lewis6991/gitsigns.nvim"
require("gitsigns").setup()

-- Repeated packages will be ignored
use "nvim-lua/plenary.nvim"
use "nvim-lua/plenary.nvim"
use "nvim-lua/plenary.nvim"
```

# News and FAQ
## The last update broke everything!
That's terrible! I probably introduced a breaking change. Try these steps.
- If you use [bootstrapping](#bootstrap-usernvim), replace your old bootstrapping code with the most recent bit.
- Then, delete `user.nvim`'s plugins directory with `rm -r ~/.local/share/nvim/site/pack/user/`.
- If it doesn't work, please file an issue!
## Packages are installing, but my config()s aren't loading!
If you are using `parallel`, then make sure you call `flush()` after your `use()` calls.

# :art: SGPL — Simple Graphics Programming Language Neovim Package
This repository contains the sgpl neovim support module.  It include syntax
highlighting, an LSP, and indent controls.

For installing with Packer add the following lines to the packaer startup:
```lua
use {
  "millipedes/sgpl_nvim",
  config = function()
    require("sgpl").setup({})
  end
}
```

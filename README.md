# snippet-converter.nvim

> :warning: This plugin is still in its early stages and not currently usable. Stay tuned!

Are you switching to a new snippet engine but don't want to lose your hand-crafted snippets?
Did you discover an awesome snippet collection but couldn't use it because your snippet engine
only supports some custom format? `snippet-converter.nvim` is here to help you out!

[Not all snippets will be convertible]

Planned API:
```lua
use {
  "smjonas/snippet-converter.nvim",
  config = function()
    require("snippet_converter").setup {
      sources = {
        {
          "vim-snippets/snippets",
          format = "snipmate",
        },
        {
          "latex-snippets/tex.snippets",
          format = "ultisnips",
        }
      },
      output = {
        path = vim.fn.stdpath("data") .. "/vscode_snippets",
        format = "vscode",
      },
    }
  end
}
```

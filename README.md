# snippet-converter.nvim

> :warning: This plugin is still in its early stages and not currently usable. Stay tuned!

Are you switching to a new snippet engine but don't want to lose your hand-crafted snippets?
Did you discover an awesome snippet collection but couldn't use it because your snippet engine
only supports some custom format? SnippetConverter is here to help you out!

### Supported snippet engines
SnippetConverter currently supports the following snippet formats:
- VSCode snippets (used by [vim-vsnip](https://github.com/hrsh7th/vim-vsnip), [LuaSnip](https://github.com/L3MON4D3/LuaSnip))
- [UltiSnips](https://github.com/SirVer/ultisnips) snippets
- [SnipMate](https://github.com/garbas/vim-snipmate) snippets

Support for the following snippet engines will be added next:
- [neosnippet.vim](https://github.com/Shougo/neosnippet.vim)

Is there any snippet engine that I missed? Please let me know by creating an issue!

| Conversion between snippet formats | UltiSnips | VSCode | SnipMate |
|------------------------------------|-----------|--------|----------|
| UltiSnips                          | -         |        |          |
| VSCode                             | &check;   | -      | &check;  |
| SnipMate                           |           |        | -        |

<sup>&check;: snippets can be converted without any loss of information</sup>

## Getting started

[Not all snippets will be convertible]

Planned API:
```lua
use {
  "smjonas/snippet-converter.nvim",
  config = function()
    require("snippet_converter").setup {
      sources = {
        ultisnips = {
          "latex-snippets/tex.snippets",
          vim.fn.stdpath("config") .. "/UltiSnips",
        },
        snipmate = {
          "vim-snippets/snippets",
        },
      },
      output = {
        path = vim.fn.stdpath("data") .. "/vscode_snippets",
        format = "vscode",
      },
    }
  end
}
```

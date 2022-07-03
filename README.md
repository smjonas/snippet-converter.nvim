<div align="center">

# snippet-converter.nvim

Parse, transform and convert snippets. Supports a variety of formats and snippet engines.

Current version: `1.2.0`

[![Neovim](https://img.shields.io/badge/Neovim%200.7+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)

<video src="https://user-images.githubusercontent.com/40792180/166674215-61bd1e8c-c307-4db9-bca1-a71f873e00ff.mp4" width="85%">

</div>

## Primary objectives
- Decouple the functionality of user's snippets from the concrete syntax or snippet engine.
- Facilitate and encourage creation and sharing of snippet collections.

## Use cases
There are several cases where this plugin comes in handy:

- You are **switching to a new snippet engine** but don't want to lose your
  hand-crafted snippets:\
  Simply let SnippetConverter convert them to your desired output format.
- You are using a collection of predefined snippets such as [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) or
  [vim-snippets](https://github.com/honza/vim-snippets), however there is that **one snippet
  that always gets in your way:**\
  Instead of maintaining your own fork of the snippet collection, simply remove or modify the snippet with a few lines of Lua code.
- You **dislike the snippets format** your snippet engine supports or find it **hard to
  create your own snippets**:\
  In that case, simply write the snippet in a nicer format (in my opinion, VSCode snippets are quite
  awkward to write in JSON, why not write them in UltiSnips format and convert them afterwards?).

Other reasons may include:
- You want to **validate the syntax** of your snippets:\
  SnippetConverter includes a graphical UI that will show you exactly where and why your snippet
  could not be parsed. You can even send the errors to the quickfix list and step through them one by one!
- You are a **plugin author** and don't want to reinvent the wheel by writing your own parsers:\
  SnippetConverter generates a standardized (format-agnostic) AST from your snippet definitions. Feel free to integrate SnippetConverter with your plugin!

### Supported snippet engines
SnippetConverter can convert snippets between the following formats:
- [VSCode](https://code.visualstudio.com/docs/editor/userdefinedsnippets) (as well as separate flavors used by [vim-vsnip](https://github.com/hrsh7th/vim-vsnip) and [LuaSnip](https://github.com/L3MON4D3/LuaSnip))
- [UltiSnips](https://github.com/SirVer/ultisnips)
- [SnipMate](https://github.com/garbas/vim-snipmate)

Support for the following formats is planned for future versions:
- Native [LuaSnip](https://github.com/L3MON4D3/LuaSnip) (that means you will be able to
  define your snippets in a simpler DSL while still benefitting from the advanced features of LuaSnip - SnippetConverter will generate the Lua code for you)
- [neosnippet.vim](https://github.com/Shougo/neosnippet.vim)

Is there any other snippet engine or custom format that you think should be supported? Let me know by creating an issue!

## Requirements
- Neovim ≥ 0.7

## Getting started

To get started, pass a Lua table with a list of templates to the `setup` function. A template must contain
`sources` (the formats and paths of your input snippets) and `output` tables (the target formats and paths).

Here's an example to convert a set of UltiSnips and SnipMate snippets to the VSCode snippets format (using packer.nvim):

```lua
use {
  "smjonas/snippet-converter.nvim",
  -- SnippetConverter uses semantic versioning. Example: use version = "1.*" to avoid breaking changes on version 1.
  -- Uncomment the next line to follow stable releases only.
  -- version = "*",
  config = function()
    local template = {
      -- name = "t1", (optionally give your template a name to refer to it in the `ConvertSnippets` command)
      sources = {
        ultisnips = {
          -- Add snippets from (plugin) folders or individual files on your runtimepath...
          "./vim-snippets/UltiSnips",
          "./latex-snippets/tex.snippets",
          -- ...or use absolute paths on your system.
          vim.fn.stdpath("config") .. "/UltiSnips",
        },
        snipmate = {
          "vim-snippets/snippets",
        },
      },
      output = {
        -- Specify the output formats and paths
        vscode_luasnip = {
          vim.fn.stdpath("config") .. "/luasnip_snippets",
        },
      },
    }

    require("snippet_converter").setup {
      templates = { template },
      -- To change the default settings (see configuration section in the documentation)
      -- settings = {},
    }
  end
}
```
Then simply run the command `:ConvertSnippets` to convert all snippets to your specified
output locations and formats. To see which output folders you should choose depending on
your snippet engine, have a look at the section [Recommended output paths](doc/documentation.md#recommended-output-paths) in the docs.

## Documentation

For more detailed instructions, info about customization and examples check out the
[documentation](doc/documentation.md) or help file with `:h snippet-converter`.

## Credits
I want to thank
- [L3MON4D3](https://github.com/L3MON4D3) for creating the awesome snippet engine engine [LuaSnip](https://github.com/L3MON4D3/LuaSnip)
  and [uga-rosa](https://github.com/uga-rosa) for permission to use the `scandir` utility function in my plugin!
- [ii14](https://github.com/ii14), a contributor to [nvim-lua/nvim-package-specification](https://github.com/nvim-lua/nvim-package-specification)
  for creating the `dedent` utility function that is used in this plugin after slight modification.
- [williamboman](https://github.com/williamboman) for his plugin [nvim-lsp-installer](https://github.com/williamboman/nvim-lsp-installer).
  The UI for SnippetConverter was heavily inspired by this plugin and his code helped me get started with Neovim's window API.

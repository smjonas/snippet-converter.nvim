<div align="center">

# snippet-converter.nvim

Neovim plugin to parse, transform and convert snippets. Supports a variety of formats and snippet engines.

[![Neovim](https://img.shields.io/badge/Neovim%200.5+-2357A143.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

</div>

> :warning: This plugin is still in its early stages and not currently usable. Stay tuned!

Are you switching to a new snippet engine but don't want to lose your hand-crafted snippets?
Did you discover an awesome snippet collection but couldn't use it because your snippet engine
only supports some custom format? Check out SnippetConverter!

### Supported snippet engines
SnippetConverter currently supports the following snippet formats:
- VSCode snippets (used by [vim-vsnip](https://github.com/hrsh7th/vim-vsnip), [LuaSnip](https://github.com/L3MON4D3/LuaSnip))
- [UltiSnips](https://github.com/SirVer/ultisnips) snippets
- [SnipMate](https://github.com/garbas/vim-snipmate) snippets

Support for the following snippet engines will be added next:
- [neosnippet.vim](https://github.com/Shougo/neosnippet.vim)

Is there any other snippet engine or custom format that you think should be supported? Let me know by creating an issue!

<table>
	<tbody>
		<tr>
			<td colspan="2" rowspan="2">Conversion between snippet formats</td>
			<td colspan="4"><i>Target format</i></td>
		</tr>
		<tr>
			<td>UltiSnips</td>
			<td>VSCode</td>
			<td>SnipMate</td>
		</tr>
		<tr>
			<td rowspan="3"><i>Source</br>format</i></td>
			<td>UltiSnips</td>
			<td>–</td>
			<td>(&uarr;)<sup>1</sup></td>
			<td>&uarr;</td>
		</tr>
		<tr>
			<td>VSCode</td>
			<td>&uarr;</td>
			<td>–</td>
			<td></td>
		</tr>
		<tr>
			<td>SnipMate</td>
			<td>&uarr;</td>
			<td>&uarr;</td>
			<td>–</td>
		</tr>
	</tbody>
</table>

<sup>&uarr;: All snippets can be converted - no exceptions.</sup>\
<sup>(&uarr;)<sup>1</sup>: Except snippets with Python / VimScript / shell code.</sup>

## Getting started

To get started, pass a Lua table with a list of templates to the `setup` function. A template must contain
`sources` (the formats and paths of your input snippets) and `output` tables (the target formats and paths).

Here's an example to convert a set of UltiSnips and SnipMate snippets to the VSCode snippets format (using packer.nvim):

```lua
use {
  "smjonas/snippet-converter.nvim",
  config = function()
    local template = {
      -- name = "My UltiSnips to VSCode template", (optionally give your template a name to refer to it in the transform stage)
      sources = {
        ultisnips = {
          -- Add snippets from (plugin) folders or individual files on your runtimepath...
          "vim-snippets/UltiSnips",
          "latex-snippets/tex.snippets",
          -- ...or use absolute paths on your system.
          vim.fn.stdpath("config") .. "/UltiSnips",
        },
        snipmate = {
          "vim-snippets/snippets",
        },
      },
      output = {
        vscode = vim.fn.stdpath("data") .. "/vscode_snippets",
      },
    }

    require("snippet_converter").setup {
      templates = { template },
      -- settings = {}, (to change the default settings, see configuration section)
    }
  end
}
```
Then simply run the command `:ConvertSnippets` to convert all snippets to your specified
output locations and formats.


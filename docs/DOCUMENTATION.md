# Documentation
- [Supported snippet formats](#supported-snippet-formats)
- [Converting snippets](#converting-snippets)
- [Transforming snippets](#transforming-snippets)
- [Sorting snippets](#sorting-snippets)
- [Customization](#customization)
- [Examples](#examples)

## Supported snippet formats

SnippetConverter can convert snippets between the following formats:
- [VSCode](https://code.visualstudio.com/docs/editor/userdefinedsnippets) (supported by [vim-vsnip](https://github.com/hrsh7th/vim-vsnip), [LuaSnip](https://github.com/L3MON4D3/LuaSnip))
- [UltiSnips](https://github.com/SirVer/ultisnips)
- [SnipMate](https://github.com/garbas/vim-snipmate)

The following table shows which snippets can be converted to a different format:

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
			<td>✓</td>
			<td>(✓)<sup>1</sup></td>
			<td>✓</td>
		</tr>
		<tr>
			<td>VSCode</td>
			<td>✓</td>
			<td>–</td>
			<td></td>
		</tr>
		<tr>
			<td>SnipMate</td>
			<td>✓</td>
			<td>✓</td>
			<td>–</td>
		</tr>
	</tbody>
</table>

<sup>✓: All snippets can be converted - no exceptions.</sup>\
<sup>(✓)<sup>1</sup>: Except snippets with python / vimscript / shell code.</sup>

Note that source and target format can be the same.
This is useful if you only want to filter certain snippets or apply any transformations to them.

## Converting snippets
In order to convert snippets from one supported format to another

## Transforming snippets
In order to convert snippets from one supported format to another

## Sorting snippets
```lua
sort = function(snippet)
  return snippet.trigger
end,
compare = function(first, second)
  return first < second (default)
end
```

## Customization

Default config:
```lua
M.DEFAULT_CONFIG = {
  settings = {
    ui = {
      use_nerdfont_icons = true,
    },
  },
}
```

You can pass a settings table to the `setup` function in order to overwrite the default settings:
```lua
require("snippet_converter").setup {
  settings = {
    -- ...
  }
}
```

`settings.ui.use_nerdfont_icons: boolean`

Specifies whether [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) icons should be used for the icons in the UI window. Set this to `false` if you are not using a Nerd Font - otherwise the icons will not be displayed correctly.

**Default:** `true`

## Examples
Modify a specific UltiSnips snippet (this effectively reverts [this](https://github.com/honza/vim-snippets/commit/2502f24) vim-snippets commit - see the related issue [#1396](https://github.com/honza/vim-snippets/issues/1396)):
```lua
transform_snippets = function(snippet, _, _)
  if snippet.path:match("vim-snippets/UltiSnips/tex.snippets") and snippet.trigger == "$$" then
    return [[
snippet im "Inline Math" w
$${1}$
endsnippet]]
  end
  return snippet
end
```

Remove all auto-triggers from UltiSnips snippets:
```lua
transform_snippets = function(snippet, _, _)
  if snippet.options and snippet.options:match("A") then
    snippet.options = snippet.options:gsub("A", "")
  end
  return snippet
end
```

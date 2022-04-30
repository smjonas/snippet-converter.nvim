## Supported snippet formats

SnippetConverter allows you to convert snippets between the following formats:
- [VSCode](https://code.visualstudio.com/docs/editor/userdefinedsnippets) (supported by [vim-vsnip](https://github.com/hrsh7th/vim-vsnip), [LuaSnip](https://github.com/L3MON4D3/LuaSnip))
- [vsnip](https://github.com/hrsh7th/vim-vsnip) (a superset of VSCode snippets)
- [UltiSnips](https://github.com/SirVer/ultisnips)
- [SnipMate](https://github.com/garbas/vim-snipmate)

The following table shows which snippets can be converted to other formats (the first column denotes the source format):

| Source format / Target format     | UltiSnips | VSCode | vsnip | SnipMate |
|-----------------------------------|-----------|--------|-------|----------|
| UltiSnips                         | ✓         | ✓[1]   | ✓ [2] | ✓ [1]    |
| VSCode                            | ✓         | ✓      | ✓     | ✓        |
| vsnip                             | ✓         | ✓ [3]  | ✓     | ✓        |
| SnipMate                          | ✓         | ✓      | ✓     | ✓        |

**Legend:**

✓: All snippets can be converted - no exceptions.

✓ [1]: All snippets except snippets with python / vimscript / shell code or regular expression triggers.

✓ [2]: All except snippets with python / shell code or regular expression triggers / transformations.

✓ [3]: All except snippets with vimscript code.

> :bulb: Note that source and target format can be the same.
> This is useful if you only want to filter certain snippets or apply transformations to them without converting them to a different format.

## Converting snippets
In order to convert snippets from one supported format to another, create a
template with the input / output formats and paths and pass it to the `setup` function
(see [Creating templates](#creating-templates)).

Then run the command `:ConvertSnippets`. A GUI window should pop up that will show you further information
about the status of the conversion.

By default, all templates that have been passed to `setup` will be executed sequentially.
If you only want to run a single template or a selection of them, pass their names to the
command (separated by spaces):

`:ConvertSnippets template_a template_b`

If you don't want the UI to be shown, use headless mode:

`:ConvertSnippets headless=true`

Alternatively, you can change the default option `headless` globally using the `default_opts` table
(see [Configuration](#configuration)).

### Creating templates

A template is simply a table that can contain any of the following keys:

`sources: table <string, string>`

A table with a list of paths per source format.
The paths can either be absolute paths or relative paths to folders or files in your Neovim runtimepath.
They may contain wildcards (`*`).
All snippet files that match any of the given paths will be parsed and converted to the respective output formats.

**Example:**

```lua
sources = {
  ultisnips = {
    -- Folders or files in the runtimepath
    "vim-snippets/UltiSnips",
    "latex-snippets/tex.snippets",
  },
  vsnip = {
   -- Absolute paths to snippet directories or files
    vim.fn.stdpath("config") .. "/vsnip-snippets",
  },
}
```

---

`output: table <string, string>`

A table with a list of paths per output format where the converted snippets will be
stored. Each path must be an absolute path to a directory.
If a directory does not exist, it will be created.

---

`transform_snippets: snippet -> snippet | nil`

An optional transformation function, see [Transforming snippets](#transforming-snippets).

---

`sort_snippets: (snippet -> snippet) -> boolean`

An optional sorting function, see [Sorting snippets](#sorting-snippets).

## Recommended output paths
Choosing the correct output paths is important to make the converted snippets available to your snippet engine.

- **LuaSnip**: LuaSnip will load VSCode or SnipMate snippets if they are stored in the Neovim
  runtimepath. Note: you need to call `require("luasnip.loaders.from_vscode").load(opts)` or
  `require("luasnip.loaders.from_snipmate").load(opts)`.

  To load snippets from different paths, pass the directories to the `opts.paths` table (see `:h luasnip-vscode-snippets-loader` for details).

  For VSCode snippets, SnippetConverter will automatically generate a `package.json` file for you.

  **Example output path:**
  ```lua
  vim.fn.stdpath("config") .. "/vscode_snippets"
  ```

## Transforming snippets
Before snippets are converted, it is possible to apply a transformation to them. Transformations can be used to either discard specific snippets or modify them arbitrarily.
They can be specified per template or globally.

The transformation function takes as parameters the `snippet` itself and a `helper` table that provides additional utilities for transforming the snippet.
If `nil` is returned, the current snippet is discarded, otherwise the snippet is replaced with the returned table.
<!-- It may return either `nil` or a table - the type determines how the snippet will be handled: -->
<!-- - `nil`: the current snippet will be discarded -->
<!-- - table: the snippet will be replaced with the returned table -->
<!-- - string: the snippet will skip be replaced  -->

The available keys in the snippet table are listed below. Optional keys can be nil.

| Key             | Type   | Supported formats         | Optional? |
|-----------------|--------|---------------------------|-----------|
| trigger         | string | All                       | No        |
| description     | string | All                       | Yes       |
| body            | table  | All                       | No        |
| scope           | table  | VSCode / vsnip            | Yes       |
| path            | string | All                       | No        |
| line\_nr        | int    | All except VSCode / vsnip | No        |
| options         | string | UltiSnips                 | Yes       |
| custom\_context | string | UltiSnips                 | Yes       |
| priority        | string | UltiSnips                 | Yes       |

The `helper` table contains the following entries:

| Key            | Type     | Explanation                                                                                     |
|----------------|----------|-------------------------------------------------------------------------------------------------|
| source\_format | string   | The input format of the snippet.                                                                |
| parse          | function | A function that takes a single string as an argument and returns the parsed snippet as a table. This is useful if you don't want to work on the AST directly. |

### Examples

Modify a specific UltiSnips snippet (this effectively reverts [this](https://github.com/honza/vim-snippets/commit/2502f24) vim-snippets commit - see the related issue [#1396](https://github.com/honza/vim-snippets/issues/1396)):
```lua
transform_snippets = function(snippet, helper)
  if snippet.path:match("vim-snippets/UltiSnips/tex.snippets") and snippet.trigger == "$$" then
    return [[
snippet im "Inline Math" w
$${1}$
endsnippet]]
  end
  return snippet
end
```

Delete all snippets with a specific trigger:
```lua
transform_snippets = function(snippet, helper)
  if snippet.trigger == "..." then
    return nil
  end
  return snippet
end
```

Remove all auto-triggers from UltiSnips snippets:
```lua
transform_snippets = function(snippet, helper)
  if snippet.options and snippet.options:match("A") then
    snippet.options = snippet.options:gsub("A", "")
  end
  return snippet
end
```

## Sorting snippets
By default, when converting snippets, the output snippets will appear in the same order
as they were defined in the input files. Snippets defined in JSON format (such as VSCode and vsnip
snippets) will be sorted alphabetically due to the way JSON files are read by Vim (the
order of the JSON objects is not preserved).

You can control the sorting behaviour by passing a `sort_snippets` function to the template or setup functions.
The `sort_snippets` function takes as parameters the two snippets to compare and must return a boolean.
When `true` is returned, the first snippet will be placed before the second one.

### Example

Here is an example that puts snippets with a priority value at the top of the output file,
sorting them by their priority in descending order, then by their trigger in ascending order:

```lua
sort_snippets = function(first, second)
  if (first.priority or -math.huge) > (second.priority or -math.huge) then
    return true
  end
  return first.trigger < second.trigger
end,
```

## Configuration

Default config:
```lua
M.DEFAULT_CONFIG = {
  settings = {
    ui = {
      use_nerdfont_icons = true,
    },
  },
  default_opts = {
    headless = false,
  },
}
```

You can pass a settings table to the `setup` function in order to overwrite the default settings or options:
```lua
require("snippet_converter").setup {
  settings = {
    -- ...
  },
  default_opts = {
    -- ...
  },
}
```

`settings.ui.use_nerdfont_icons: boolean`

Specifies whether [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) icons should be used for the icons in the UI window. Set this to `false` if you are not using a Nerd Font - otherwise the icons will not be displayed correctly.

**Default:** `true`

---

`default_opts.headless: boolean`

Specifies whether the `:ConvertSnippets` command should run in headless mode.
If set to `false`, a UI window will show the status of the conversion operation.

**Default:** `false`

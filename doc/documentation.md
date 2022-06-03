SnippetConverter is a Neovim plugin that allows you to convert snippets (such as VSCode snippets, UltiSnips snippets etc.)
between different formats. This allows users to reuse their snippets when switching to a different snippet
engine by first converting them to a supported format.
The aim of this plugin is to make it easier for users to create and share snippets as they become "snippet-engine-agnostic".
Additionally, it provides the ability to modify individual snippets using a few lines of Lua code.

# Supported snippet formats

SnippetConverter supports conversion between the folowing formats:
- **[VSCode](https://code.visualstudio.com/docs/editor/userdefinedsnippets)** (supported by [vim-vsnip](https://github.com/hrsh7th/vim-vsnip), [LuaSnip](https://github.com/L3MON4D3/LuaSnip))
- **VSCode LuaSnip**: a superset of VSCode snippets

LuaSnip snippets can contain a custom `luasnip` key. That is why `vscode_luasnip` has been added as a separate format. For example, if converting an UltiSnips snippet,
and the option `A` is present, the `luasnip.autotrigger` key will be set to `true`.

- **vsnip**: a superset of VSCode snippets (vsnip snippets can contain Vimscript code)

- **[UltiSnips](https://github.com/SirVer/ultisnips)**
- **[SnipMate](https://github.com/garbas/vim-snipmate)**

The following table shows which snippets can be converted to another format (the first column denotes the source format):

| Source format / Target format     | vscode | vscode\_luasnip | vsnip | ultisnips | snipmate | snipmate\_luasnip |
|-----------------------------------|--------|-----------------|-------|-----------|----------|-------------------|
| vscode                            | ✓      | ✓               | ✓     | ✓         | ✓        | ✓                 |
| vscode\_luasnip                   | ✓      | ✓               | ✓     | ✓         | ✓        | ✓                 |
| vsnip                             | ✓ [1]  | ✓ [1]           | ✓     | ✓         | ✓ [1]    | ✓ [1]             |
| ultisnips                         | ✓ [2]  | ✓ [2]           | ✓ [3] | ✓         | ✓ [2]    | ✓ [2]             |
| snipmate                          | ✓      | ✓               | ✓     | ✓         | ✓        | ✓ [1]             |
| snipmate\_luasnip                 | ✓      | ✓               | ✓     | ✓         | ✓        | ✓                 |

**Legend:**

✓: All snippets can be converted - no exceptions.

✓ [1]: All except snippets with vimscript code.

✓ [2]: All snippets except snippets with python / vimscript / shell code or regular expression triggers.

✓ [3]: All except snippets with python / shell code or regular expression triggers / transformations.

> :bulb: Note that source and target format can be the same.
> This is useful if you only want to filter certain snippets or apply transformations to them without converting them to a different format.

# Converting snippets
In order to convert snippets from one supported format to another, create a
template with the input / output formats and paths and pass it to the `setup` function
(see [Creating templates](#creating-templates)).
Then run the command `:ConvertSnippets`. A floating window will pop up that shows you further information
about the status of the conversion such as syntax errors.

By default, all templates that have been passed to `setup` will be executed sequentially.
If you only want to run a single template or a selection of them, pass their names to the
command (separated by spaces):

`:ConvertSnippets template_a template_b`

If you don't want the UI to be shown, use headless mode:

`:ConvertSnippets headless=true`

Alternatively, you can change the default option `headless` globally using the `default_opts` table
(see [Configuration](#configuration)).

## Creating templates

A template is simply a table that describes the input / output formats and paths of a conversion.
Templates must be passed to the `setup` function as a list:
```lua
local template = {
  sources = {
    ultisnips = {
      -- Folders or files in the runtimepath
      "./vim-snippets/UltiSnips",
      "./latex-snippets/tex.snippets",
    },
    vsnip = {
    -- Absolute paths to snippet directories or files
      vim.fn.stdpath("config") .. "/vsnip-snippets",
    },
  }
}

require("snippet_converter").setup {
  templates = {
    template,
    -- other templates...
  }
}
```
It can contain any of the following keys:

---

`name: string?`

An optional name that can be passed as an argument to the `:ConvertSnippets` command.
If not specified, a default value (the index of the template in the `templates` table passed to `setup`) will be used.

---

`sources: table <string, string>`

A table with a list of paths per source format.
For a list of available source formats, see [Supported snippet formats](#supported-snippet-formats).
The paths can either be absolute paths or relative paths to folders or files in your Neovim runtimepath. For the latter, prefix the path with `./`.

All snippet files that match any of the given paths will be parsed and converted to the specified output formats. However, a path that also matches any output
path of the same template will be ignored! This is to avoid reconverting snippets that have already been converted in a previous run.

---

`output: table <string, string>`

A table with a list of paths per output format where the converted snippets will be stored.
Each path must be an absolute path to a directory.
If a directory does not exist, it will be created.
See [Recommended output paths](#transforming-snippets) for advice on how to choose a suitable output path.

---

`transform_snippets: snippet -> snippet | nil`

An optional transformation function, see [Transforming snippets](#transforming-snippets).

---

`sort_snippets: (snippet -> snippet) -> boolean`

An optional sorting function, see [Sorting snippets](#sorting-snippets).

## Recommended output paths
Choosing the correct output paths is important to make the converted snippets available to your snippet engine.
For details, always refer to the documentation of your snippet engine.

### LuaSnip

- LuaSnip will load VSCode or SnipMate snippets if they are stored in your Neovim
  runtimepath. Note: you need to call `require("luasnip.loaders.from_vscode").load(opts)` or
  `require("luasnip.loaders.from_snipmate").load(opts)` in your config.

  To load snippets from locations outside of your runtimepath, pass a list of paths to the `opts.paths` table.
  Example: use `{ paths = "./vscode_snippets" }` to load snippets at `vim.fn.stdpath("config") .. "/vscode_snippets"`.

  Therefore, the following is a suitable output path for your generated snippets:
  ```lua
  vim.fn.stdpath("config") .. "/vscode_snippets"
  ```

  For VSCode snippets, SnippetConverter will automatically generate the required `package.json` file in the root directory.

### UltiSnips

- By default, UltiSnips will look for snippets inside `UltiSnips` and `snippets` folders in your runtimepath (the latter is used for SnipMate snippets).
  Thus, a valid output path is:
  ```lua
  vim.fn.stdpath("config") .. "/UltiSnips"
  ```
  This can be changed by modifying the global table variable `vim.g.UltiSnipsSnippetDirectories`.

### Vsnip

- Similarly to LuaSnip, vsnip can load VSCode snippets that are present in a `snippets` folder in your runtimepath.
  (SnippetConverter supports snippets that use the Vimscript interpolation feature of vsnip.)
  Custom snippets can be added at the location of `vim.g.vsnip_snippet_dir` (which is `~/.vsnip` by default) by running the `:VsnipOpen` command.
  So the following are valid output paths:
  ```lua
  vim.g.vsnip_snippet_dir
  -- or
  vim.fn.stdpath("config") .. "/snippets"
  ```

### SnipMate

- SnipMate can find snippets inside `snippets` folders in your runtimepath, so a valid output path would be:
  ```lua
  vim.fn.stdpath("config") .. "/snippets"
  ```

# Transforming snippets
Before snippets are converted, it is possible to apply a transformation on them. Transformations can be used to either discard specific snippets or modify them arbitrarily.
They can be specified per template or globally (the global transform function will be run last).

The transformation function takes as parameters the `snippet` itself and a `helper` table that provides additional utilities for transforming the snippet.
If `false` is returned, the current snippet is discarded. If a non-nil value is returned, the snippet is replaced with the result of parsing the returned value
(the snippet format must match the source format). For VSCode snippets, this must be a table, for other formats it is a string (see examples).
It is possible to return multiple snippets.

> :bulb: It is possible to return multiple snippets. This allows you to turn an existing
> snippet into multiple new ones. [An example would be great here, let me know if you have one to share!]

In contrast to loaded snippets, any errors that occur during parsing will be shown to the user immediately.

The available keys in the snippet table are listed below. Optional keys can be nil.

| Key             | Type    | Source formats                                      | Optional? |
|-----------------|---------|-----------------------------------------------------|-----------|
| trigger         | string  | All                                                 | No        |
| description     | string  | All                                                 | Yes       |
| body            | table   | All                                                 | No        |
| scope           | table   | `vscode` / `vscode_luasnip` / `vsnip`               | Yes       |
| path            | string  | All                                                 | No        |
| line\_nr        | int     | All except `vscode` / `vscode_luasnip` / `vsnip`    | No        |
| options         | string  | `ultisnips`                                         | Yes       |
| custom\_context | string  | `ultisnips`                                         | Yes       |
| priority        | number  | `vscode_luasnip` / `ultisnips` / `snipmate_luasnip` | Yes       |
| autotrigger     | boolean | `vscode_luasnip`                                    | Yes       |

The `helper` table contains the following entries:

| Key            | Type     | Explanation                                                                                                                                                                            |
|----------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| source\_format | string   | The input format of the snippet.                                                                                                                                                       |
| target\_format | string   | The output format of the snippet.                                                                                                                                                      |
| dedent         | function | A function that takes a single string as an argument and removes leading whitespace from all lines. The indentation is inferred from the first line. This allows for nicer formatting. |

Optionally, a table of options can be returned as a second value which may contain any of the following items:

| Key             | Type    | Default                    | Description                                                                                                              |
|-----------------|---------|----------------------------|--------------------------------------------------------------------------------------------------------------------------|
| replace         | boolean | `true`                     | If `true`, the current existing snippet will be replaced with the new one(s), otherwise it will be kept.                 |
| format          | string  | source\_format             | The format of the snippet which determines the parser to be used. Useful if you prefer a particular syntax over another. |

## Examples

Modify a specific UltiSnips snippet (this effectively reverts [this](https://github.com/honza/vim-snippets/commit/2502f24) vim-snippets commit - see the related issue [#1396](https://github.com/honza/vim-snippets/issues/1396)):
```lua
transform_snippets = function(snippet, helper)
  if snippet.path:find("vim-snippets/.*/tex%.snippets") and snippet.trigger == "$$" then
    return helper.dedent([[
      snippet im "Inline Math" w
      $${1}$
      endsnippet
    ]]),
    -- These are the default options (could be omitted)
    { replace = true, format = "ultisnips" }
  end
end
```

Here is an example for VSCode snippets (this needs to match the default syntax of VSCode
snippets, e.g. use `prefix` instead of `trigger`):
```lua
transform_snippets = function(snippet, helper)
  if snippet.trigger == "if" then
    return {
      ["if"] = {
        prefix = "if",
        body = { "if ${1:condition} then", "\t$0", "end" },
      }
    }
  end
end
```

Delete all snippets with a specific trigger:
```lua
transform_snippets = function(snippet, helper)
  if snippet.trigger == "..." then
    return false
  end
end
```

Remove all auto-triggers from UltiSnips snippets:
```lua
transform_snippets = function(snippet, helper)
  if snippet.options and snippet.options:match("A") then
    snippet.options = snippet.options:gsub("A", "")
  end
end
```

# Sorting snippets
By default, when converting snippets, the output snippets will appear in the same order
as they were defined in the input files. Snippets defined in JSON format (such as VSCode and vsnip
snippets) will be sorted alphabetically due to the way JSON files are read by Neovim (the
order of JSON keys is not preserved).

You can control the sorting behaviour by passing a `sort_snippets` function to the template or setup functions.
This function takes as parameters the two snippets to compare and must return a boolean.
When `true` is returned, the first snippet will be placed before the second one, otherwise the second one comes before the first one.

## Examples

The following example will sort the snippets by their trigger in ascending order:
```lua
sort_snippets = function(first, second)
  return first.trigger < second.trigger
end
```

A more advanced example puts snippets with a priority value at the top of the output file,
sorting them by their priority in descending order, then by their trigger in ascending order:

```lua
sort_snippets = function(first, second)
  if (first.priority or -math.huge) > (second.priority or -math.huge) then
    return true
  end
  return first.trigger < second.trigger
end,
```

# Configuration

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

Default config:
```lua
DEFAULT_CONFIG = {
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
Here are the available settings:

---

`settings.ui.use_nerdfont_icons: boolean`

Specifies whether [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) icons should be used for the icons in the floating window. Set this to `false` if you are not using a Nerd Font - otherwise the icons will not be displayed correctly.

**Default:** `true`

---

`default_opts.headless: boolean`

Specifies whether the `:ConvertSnippets` command should run in headless mode.
If set to `false`, a floating window will show the status of the conversion operation.

**Default:** `false`

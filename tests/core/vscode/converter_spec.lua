local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.vscode.converter")

describe("VSCode converter should", function()
  it("convert basic snippet to JSON", function()
    local snippet = {
      trigger = "fn",
      description = "function",
      scope = { "javascript", "typescript" },
      -- "local ${1:name} = function($2)"
      body = {
        { type = NodeType.TEXT, text = "local " },
        {
          type = NodeType.PLACEHOLDER,
          int = "1",
          any = { { type = NodeType.TEXT, text = "name" } },
        },
        { type = NodeType.TEXT, text = " = function(" },
        { type = NodeType.TABSTOP, int = "2" },
        { type = NodeType.TEXT, text = ")" },
      },
    }
    local actual = converter.convert(snippet)
    local expected = {
      trigger = "fn",
      description = "function",
      scope = "javascript,typescript",
      body = "local ${1:name} = function($2)",
    }
    assert.are_same(expected, actual)
  end)

  it("correctly escape curly brace preceded by backslashes", function()
    local snippet = {
      trigger = "fn",
      body = {
        { type = NodeType.TEXT, text = [[\\{$1\\} $0]] },
      },
    }
    local actual = converter.convert(snippet)
    local expected = {
      trigger = "fn",
      -- In .convert, '\' was not yet escaped for JSON export
      body = [[\\{\$1\\\} \$0]],
    }
    assert.are_same(expected, actual)
  end)

  it("handle missing description with multiple lines in body", function()
    local snippet = {
      trigger = "fn",
      body = {
        { type = NodeType.TEXT, text = "local " },
        {
          type = NodeType.PLACEHOLDER,
          int = "1",
          any = { { type = NodeType.TEXT, text = "name" } },
        },
        { type = NodeType.TEXT, text = " = function(" },
        { type = NodeType.TABSTOP, int = "2" },
        { type = NodeType.TEXT, text = ")\nnewline" },
      },
    }
    local expected = {
      trigger = "fn",
      body = { "local ${1:name} = function($2)", "newline" },
    }
    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)

  it("convert choice node", function()
    local snippet = {
      trigger = "fn",
      body = {
        { type = NodeType.CHOICE, int = "1", text = { "a", "b", "c" } },
        { type = NodeType.CHOICE, int = "2", text = { "a" } },
      },
    }
    local expected = {
      trigger = "fn",
      body = "${1|a,b,c|}${2|a|}",
    }
    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)

  local function create_format_snippet(replacement)
    return {
      trigger = "fn",
      body = {
        {
          int = "1",
          transform = {
            regex = "",
            regex_kind = NodeType.RegexKind.JAVASCRIPT,
            options = "",
            replacement = replacement,
            type = NodeType.TRANSFORM,
          },
          type = NodeType.TABSTOP,
        },
      },
    }
  end

  it("convert format node with format modifier", function()
    local snippet = create_format_snippet {
      { int = "2", format_modifier = "upcase", type = NodeType.FORMAT },
    }
    local expected = {
      trigger = "fn",
      body = "${1//${2:/upcase}/}",
    }
    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)

  it("convert format node without if and else text", function()
    local snippet = create_format_snippet { { int = "2", type = NodeType.FORMAT } }
    local expected = {
      trigger = "fn",
      body = "${1//$2/}",
    }
    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)

  it("convert format node with if text", function()
    local snippet = create_format_snippet { { if_text = "if_text", int = "2", type = NodeType.FORMAT } }
    local expected = {
      trigger = "fn",
      body = "${1//${2:+if_text}/}",
    }
    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)

  it("convert format node with else text", function()
    local snippet = create_format_snippet { { else_text = "else_text", int = "2", type = NodeType.FORMAT } }
    local expected = {
      trigger = "fn",
      body = "${1//${2:-else_text}/}",
    }
    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)

  it("convert format node with if and else text", function()
    local snippet = create_format_snippet {
      { if_text = "if_text", else_text = "else_text", int = "2", type = NodeType.FORMAT },
    }
    local expected = {
      trigger = "fn",
      body = "${1//${2:?if_text:else_text}/}",
    }
    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)
end)

describe("VSCode converter should fail to convert", function()
  it("snippet with non-VSCode regex in transform node", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          type = NodeType.TABSTOP,
          transform = {
            type = NodeType.TRANSFORM,
            regex = "(.*)",
            regex_kind = NodeType.RegexKind.PYTHON,
            replacement = {
              { text = "abc", type = NodeType.TEXT },
            },
            options = "",
          },
        },
      },
    }
    local ok, msg = pcall(converter.convert, snippet)
    assert.is_false(ok)
    assert.are_same("conversion of Python regex in transform node is not supported", msg)
  end)

  it("snippet with YASnippet transform node", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          type = NodeType.TABSTOP,
          int = "2",
          -- YASnippet transform nodes don't have a regex kind
          transform = {
            type = NodeType.TRANSFORM,
            replacement = "capitalize yas-text",
          },
        },
      },
    }
    local ok, msg = pcall(converter.convert, snippet)
    assert.is_false(ok)
    assert.are_same("conversion of YASnippet transform node is not supported", msg)
  end)
end)

describe("VSCode converter (luasnip flavor) should", function()
  it("not create empty luasnip table", function()
    local snippet = {
      trigger = "fn",
      body = {},
    }
    local actual = converter.convert(snippet, nil, { flavor = "luasnip" })
    local expected = {
      trigger = "fn",
      body = "",
    }
    assert.are_same(expected, actual)
  end)

  it("convert autotrigger key from options", function()
    local snippet = {
      trigger = "fn",
      body = {},
      options = "iA",
      luasnip = {
        autotrigger = false,
      },
    }
    local actual = converter.convert(snippet, nil, { flavor = "luasnip" })
    local expected = {
      trigger = "fn",
      body = "",
      -- Original key is not modified (but ignored during export)
      options = "iA",
      luasnip = {
        autotrigger = true,
      },
    }
    assert.are_same(expected, actual)
  end)

  it("should convert autotrigger flag", function()
    local snippet = {
      trigger = "fn",
      body = {},
      autotrigger = true,
    }
    local actual = converter.convert(snippet, nil, { flavor = "luasnip" })
    local expected = {
      trigger = "fn",
      body = "",
      -- Original key is not modified
      autotrigger = true,
      luasnip = {
        autotrigger = true,
      },
    }
    assert.are_same(expected, actual)
  end)

  it("convert priority", function()
    local snippet = {
      trigger = "fn",
      body = { { type = NodeType.TEXT, text = "txt" } },
      priority = 100,
    }
    local actual = converter.convert(snippet, nil, { flavor = "luasnip" })
    local expected = {
      trigger = "fn",
      body = "txt",
      -- Original key is not modified
      priority = 100,
      luasnip = {
        priority = 100,
      },
    }
    assert.are_same(expected, actual)
  end)

  it("not convert variable nodes to Vimscript", function()
    local snippet = {
      trigger = "fn",
      body = {
        { type = NodeType.VARIABLE, var = "CURRENT_YEAR" },
        {
          type = NodeType.VARIABLE,
          var = "CURRENT_YEAR",
          any = {
            { type = NodeType.TEXT, text = "txt" },
          },
        },
        {
          type = NodeType.VARIABLE,
          var = "CURRENT_YEAR",
          any = {
            { type = NodeType.VARIABLE, var = "CURRENT_MONTH" },
          },
        },
      },
    }
    local actual = converter.convert(snippet, nil, { flavor = "luasnip" })
    assert.are_same({
      trigger = "fn",
      body = "${CURRENT_YEAR}${CURRENT_YEAR:txt}${CURRENT_YEAR:${CURRENT_MONTH}}",
    }, actual)
  end)
end)

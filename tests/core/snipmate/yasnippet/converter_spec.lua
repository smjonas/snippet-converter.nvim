local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.snipmate.yasnippet.converter")

describe("YASnippet converter should", function()
  it("convert basic snippet", function()
    local snippet = {
      trigger = "fn",
      description = "a function",
      -- AST of snippet body
      body = {
        { type = NodeType.TEXT, text = "function " },
        {
          type = NodeType.PLACEHOLDER,
          int = "1",
          any = { { type = NodeType.TEXT, text = "name" } },
        },
        { type = NodeType.TEXT, text = "(" },
        { type = NodeType.TABSTOP, int = "2" },
        { type = NodeType.TEXT, text = ")\n\t" },
        {
          type = NodeType.PLACEHOLDER,
          int = "3",
          any = { { type = NodeType.TEXT, text = "-- code" } },
        },
        { type = NodeType.TEXT, text = "\nend" },
      },
    }
    local actual = converter.convert(snippet).body
    local expected = [[
# name: a function
# key: fn
# --
function ${1:name}($2)
	${3:-- code}
end]]
    assert.are_same(expected, actual)
  end)

  it("convert snippet with tabstop + transformation", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          type = NodeType.TABSTOP,
          int = "1",
          transform = {
            replacement = "capitalize yas-text",
          },
        },
      },
    }
    local actual = converter.convert(snippet).body
    local expected = [[
# key: fn
# --
${1:capitalize yas-text}]]
    assert.are_same(expected, actual)
  end)

  it("convert Emacs-Lisp code", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          type = NodeType.EMACS_LISP_CODE,
          code = "yas-selected-text",
        },
      },
    }
    local actual = converter.convert(snippet).body
    local expected = [[
# key: fn
# --
`yas-selected-text`]]
    assert.are_same(expected, actual)
  end)

  it("remove trailing whitespace from description", function()
    local snippet = {
      trigger = "fn",
      description = "desc 	",
      body = { { type = NodeType.TEXT, text = "body" } },
    }
    local actual = converter.convert(snippet).body
    local expected = [[
# name: desc
# key: fn
# --
body]]
    assert.are_same(expected, actual)
  end)

  it("replace newline characters with whitespace in description", function()
    local snippet = {
      trigger = "fn",
      description = [[
First line
Second line]],
      body = { { type = NodeType.TEXT, text = "body" } },
    }
    local actual = converter.convert(snippet).body
    local expected = [[
# name: First line Second line
# key: fn
# --
body]]
    assert.are_same(expected, actual)
  end)
end)

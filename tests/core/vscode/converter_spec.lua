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

  it("not convert snippet with non-VSCode regex in transform node", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          type = NodeType.TABSTOP,
          transform = {
            -- TODO: remove type from transform node
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
    assert.are_same(msg, "conversion of Python regex in transform node is not supported")
  end)
end)

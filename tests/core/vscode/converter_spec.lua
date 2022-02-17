local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.vscode.converter")

describe("VSCode converter", function()
  describe("should convert snippet to JSON", function()
    it("(basic)", function()
      local snippet = {
        trigger = "fn",
        description = "function",
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
      local expected = [[
  "fn": {
    "prefix": "fn",
    "description": "function",
    "body": "local ${1:name} = function($2)"
  }]]
      assert.are_same(expected, actual)
    end)

    it("(missing description with multiple lines)", function()
      local snippet = {
        trigger = "fn",
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
          { type = NodeType.TEXT, text = "\nnewline" },
        },
      }
      local actual = converter.convert(snippet)
      local expected = [[
  "fn": {
    "prefix": "fn",
    "body": ["local ${1:name} = function($2)", "newline"]
  }]]
      assert.are_same(expected, actual)
    end)
  end)
end)

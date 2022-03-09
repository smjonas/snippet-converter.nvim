local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.vscode.converter")

describe("VSCode converter", function()
  describe("should convert snippet to JSON", function()
    it("(basic)", function()
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
      local expected = [[
  "fn": {
    "prefix": "fn",
    "description": "function",
    "scope": "javascript,typescript",
    "body": "local ${1:name} = function($2)"
  }]]
      assert.are_same(expected, actual)
    end)

    it("and escape backslashes in text node correctly", function()
      local snippet = {
        trigger = "test",
        body = {
          {
            type = NodeType.TEXT,
            -- "bdf" is intentional to test that \b is correctly escaped
            text = "\\bdfminorversion=7\n\t\\usepackage{\\\\pdfpages}\n\\usepackage{transparent}",
          },
        },
      }
      local expected = [[
  "test": {
    "prefix": "test",
    "body": [
      "\\bdfminorversion=7",
      "\t\\usepackage{\\\\pdfpages}",
      "\\usepackage{transparent}"
    ]
  }]]
      assert.are_same(expected, converter.convert(snippet))
    end)

    it("and escape backslashes + quotes in trigger and description correctly", function()
      local snippet = {
        trigger = "\\test",
        description = [["a" \test]],
        body = {
          {
            type = NodeType.TEXT,
            text = "...",
          },
        },
      }
      local expected = [[
  "\\test": {
    "prefix": "\\test",
    "description": "\"a\" \\test",
    "body": "..."
  }]]
      assert.are_same(expected, converter.convert(snippet))
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
          { type = NodeType.TEXT, text = ")\nnewline" },
        },
      }
      local actual = converter.convert(snippet)
      local expected = [[
  "fn": {
    "prefix": "fn",
    "body": [
      "local ${1:name} = function($2)",
      "newline"
    ]
  }]]
      assert.are_same(expected, actual)
    end)
  end)
end)

local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.snipmate.converter")

describe("SnipMate converter", function()
  describe("should convert snippet", function()
    it("(basic)", function()
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
      local actual = converter.convert(snippet, "")
      local expected = [[
snippet fn a function
	function ${1:name}($2)
		${3:-- code}
	end]]
      assert.are_same(expected, actual)
    end)
  end)
end)

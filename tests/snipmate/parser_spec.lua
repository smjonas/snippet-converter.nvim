local parser = require "snippet_converter.snipmate.parser"

describe("SnipMate parser", function()
  describe("should parse", function()
    it("multiple snippets", function()
      local lines = vim.split(
        [[
snippet fn function
	function ${1:name}($2)
		${3:-- code}
	end

# A comment
snippet for
	for ${1:i}=${2:1},${3:10} do
		${0:print(i)}
	end

      ]],
        "\n"
      )
      local expected = {
        {
          trigger = "fn",
          description = "function",
          body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
        },
        {
          trigger = "for",
          body = { "for ${1:i}=${2:1},${3:10} do", "\t${0:print(i)}", "end" },
        },
      }
      local actual = parser.parse(lines)
      assert.are_same(expected, actual)
    end)
  end)
end)

local parser = require("snippet_converter.ultisnips.parser")

describe("UltiSnips parser", function()
  describe("should parse", function()
    it("multiple snippets", function()
      local lines = vim.split([[
snippet fn "function" bA
function ${1:name}($2)
	${3:-- code}
end
endsnippet

hey
snippet for
for ${1:i}=${2:1},${3:10} do
	${0:print(i)}
end
endsnippet

      ]], "\n")
      local expected = {
        {
          trigger = "fn",
          description = "function",
          options = "bA",
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

local parser = require("snippet_converter.core.ultisnips.parser")

describe("UltiSnips parser", function()
  local parsed_snippets, parser_errors
  before_each(function()
    parsed_snippets = {}
    parser_errors = {}
  end)

  describe("should parse", function()
    it("multiple snippets", function()
      local lines = vim.split(
        [[
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

      ]],
        "\n"
      )
      parser.get_lines = function(_)
        return lines
      end

      local num_new_snippets = parser.parse(nil, parsed_snippets, parser_errors)
      assert.are_same(2, num_new_snippets)
      assert.are_same({}, parser_errors)
      -- TODO: test line number
    end)
  end)
end)

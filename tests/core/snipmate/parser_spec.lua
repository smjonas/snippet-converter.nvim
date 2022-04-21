local assertions = require("tests.custom_assertions")
local parser = require("snippet_converter.core.snipmate.parser")

describe("SnipMate parser", function()
  setup(function()
    assertions.register(assert)
  end)

  local parsed_snippets, parser_errors
  before_each(function()
    parsed_snippets = {}
    parser_errors = {}
  end)

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
      parser.get_lines = function(_)
        return lines
      end

      parsed_snippets = {}
      local num_new_snippets = parser.parse("/some/snippet/path.snippets", parsed_snippets, parser_errors)

      assert.are_same({}, parser_errors)
      assert.are_same(2, num_new_snippets)

      -- The pairs function does not specify the order in which the snippets will be traversed in,
      -- so we need to check both of the two possibilities. We don't check the actual
      -- contents of the AST because that is tested in snipmate/body_parser.

      local expected_fn = {
        trigger = "fn",
        description = "function",
        body_length = 7,
        path = "/some/snippet/path.snippets",
        line_nr = 1,
      }

      local expected_for = {
        trigger = "for",
        description = nil,
        body_length = 9,
        path = "/some/snippet/path.snippets",
        line_nr = 7,
      }

      if parsed_snippets[1].trigger == "fn" then
        assert.matches_snippet(expected_fn, parsed_snippets[1])
        assert.matches_snippet(expected_for, parsed_snippets[2])
      elseif parsed_snippets[1].trigger == "for" then
        assert.matches_snippet(expected_for, parsed_snippets[1])
        assert.matches_snippet(expected_fn, parsed_snippets[2])
      else
        -- This should never happen unless the parser fails.
        assert.is_false(true)
      end
    end)
  end)
end)

local parser = require("snippet_converter.core.ultisnips.parser")

describe("UltiSnips parser", function()
  local parsed_snippets, parser_errors
  before_each(function()
    parsed_snippets = {}
    parser_errors = {}
  end)

  it("should parse multiple snippets", function()
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
endsnippet]],
      "\n"
    )
    parser.get_lines = function(_)
      return lines
    end

    local num_new_snippets = parser.parse(
      "/some/snippet/path.snippets",
      parsed_snippets,
      parser_errors
    )
    assert.are_same(2, num_new_snippets)
    assert.are_same({}, parser_errors)

    -- The pairs function does not specify the order in which the snippets will be traversed in,
    -- so we need to check both of the two possibilities. We don't check the actual
    -- contents of the AST because that is tested in vscode/body_parser.
    if parsed_snippets[1].trigger == "fn" then
      assert.are_same("function", parsed_snippets[1].description)
      assert.are_same(7, #parsed_snippets[1].body)
    elseif parsed_snippets[1].trigger == "for" then
      assert.is_nil(parsed_snippets[1].description)
      assert.are_same(9, #parsed_snippets[1].body)
    else
      -- This should never happen unless the parser fails.
      assert.is_false(true)
    end
  end)

  it("should return correct info on parse failure", function()
    local lines = vim.split(
      [[
snippet fn "function"
function ${1:name}($2)
endsnippet

hey
snippet for
line 7: if($1) {
	line 8: $2
}
endsnippet]],
      "\n"
    )
    parser.get_lines = function(_)
      return lines
    end

    local num_new_snippets = parser.parse("the_snippet_path", parsed_snippets, parser_errors)
    assert.are_same(1, num_new_snippets)
    assert.are_same({
      {
        msg = [[unescaped char at '{' (input string: 'line 7: if($1) {...')]],
        path = "the_snippet_path",
        line_nr = 7,
      },
    }, parser_errors)
  end)
end)

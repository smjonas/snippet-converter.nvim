local assertions = require("tests.custom_assertions")
local parser = require("snippet_converter.core.ultisnips.parser")

describe("UltiSnips parser", function()
  setup(function()
    assertions.register(assert)
  end)

  local parsed_snippets, parser_errors, context
  before_each(function()
    parsed_snippets = {}
    parser_errors = {}
    context = {}
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
      parser_errors,
      context
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

  -- TODO: fix, also fail on invalid header
  it("should return correct info on header parse failure", function()
    local lines = vim.split(
      [[
snippet a b c d
function ${1:name}($2)
endsnippet

hey
snippet for
line 7: $1
	line 8: $2
}
endsnippet]],
      "\n"
    )
    parser.get_lines = function(_)
      return lines
    end

    local num_snippets = parser.parse("the_snippet_path", parsed_snippets, parser_errors)
    assert.are_same({
      {
        msg = "invalid snippet header",
        path = "the_snippet_path",
        line_nr = 1,
      },
    }, parser_errors)
    assert.are_same({}, context)
    assert.are_same(1, num_snippets)
  end)

  it("should parse global python code and provide it as context", function()
    local lines = vim.split(
      [[
global !p
def join(a, b):
  return a + b
endglobal

hey
snippet for
for ${1:i}=${2:1},${3:10} do
	${0:print(i)}
end
endsnippet

global !p
def join2(a, b):
  return a + b
endglobal]],
      "\n"
    )
    parser.get_lines = function(_)
      return lines
    end

    context.global_code = {}
    local num_new_snippets = parser.parse(
      "/some/snippet/path.snippets",
      parsed_snippets,
      parser_errors,
      context
    )
    assert.are_same(1, num_new_snippets)
    assert.are_same("for", parsed_snippets[1].trigger)
    assert.are_same({}, parser_errors)
    local expected_context = {
      global_code = {
        { "def join(a, b):", "  return a + b" },
        { "def join2(a, b):", "  return a + b" },
      },
    }
    assert.are_same(expected_context, context)
  end)

  it("should parse priorities and store them in snippet definition", function()
    local lines = vim.split(
      [[
priority 100

snippet fn "function" bA
function ${1:name}($2)
	${3:-- code}
end
endsnippet

priority -50
snippet for
for ${1:i}=${2:1},${3:10} do
	${0:print(i)}
end
endsnippet
priority 50]],
      "\n"
    )
    parser.get_lines = function(_)
      return lines
    end

    local expected_fn = {
      trigger = "fn",
      description = "function",
      options = "bA",
      body_length = 7,
      priority = "100",
      path = "/some/snippet/path.snippets",
      line_nr = 3,
    }

    local expected_for = {
      trigger = "for",
      body_length = 9,
      priority = "-50",
      path = "/some/snippet/path.snippets",
      line_nr = 10,
    }

    local num_new_snippets = parser.parse(
      "/some/snippet/path.snippets",
      parsed_snippets,
      parser_errors,
      context
    )

    assert.are_same(2, num_new_snippets)
    assert.are_same({}, parser_errors)

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

  it("should return errors for invalid priorities", function()
    local lines = vim.split(
      [[
priority

snippet fn "function" bA
function ${1:name}($2)
	${3:-- code}
end
endsnippet

priority - 50
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
      parser_errors,
      context
    )
    assert.are_same(2, num_new_snippets)

    local expected_errors = {
      {
        line_nr = 1,
        msg = [[invalid priority "priority"]],
        path = "/some/snippet/path.snippets",
      },
      {
        line_nr = 9,
        msg = [[invalid priority "priority - 50"]],
        path = "/some/snippet/path.snippets",
      },
    }
    assert.are_same(expected_errors, parser_errors)
  end)

  it("should parse custom context and store them in snippet definition", function()
    local lines = vim.split(
      [[
context "ctx"

snippet fn "function" bA
function ${1:name}($2)
	${3:-- code}
end
endsnippet

context "math()"
snippet for
for ${1:i}=${2:1},${3:10} do
	${0:print(i)}
end
endsnippet
context "1"]],
      "\n"
    )
    parser.get_lines = function(_)
      return lines
    end

    local expected_fn = {
      trigger = "fn",
      description = "function",
      options = "bA",
      body_length = 7,
      custom_context = "ctx",
      path = "/some/snippet/path.snippets",
      line_nr = 3,
    }

    local expected_for = {
      trigger = "for",
      body_length = 9,
      custom_context = "math()",
      path = "/some/snippet/path.snippets",
      line_nr = 10,
    }

    context.priorities = {}
    local num_new_snippets = parser.parse(
      "/some/snippet/path.snippets",
      parsed_snippets,
      parser_errors,
      context
    )

    assert.are_same(2, num_new_snippets)
    assert.are_same({}, parser_errors)

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

  -- TODO: invalid context test
end)

local assertions = require("tests.custom_assertions")
local parser = require("snippet_converter.core.vscode.parser")

describe("VSCode parser", function()
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
      local data = {
        ["a function"] = {
          prefix = "fn",
          description = "function",
          body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
        },
        ["for"] = {
          prefix = "for",
          body = { "for ${1:i}=${2:1},${3:10} do", "\t${0:print(i)}", "end" },
        },
      }
      parsed_snippets = {}
      local num_new_snippets = parser.parse(data, parsed_snippets, parser_errors)
      assert.is_true(type(parsed_snippets) == "table")

      -- The pairs function does not specify the order in which the snippets will be traversed in,
      -- so we need to check both of the two possibilities. We don't check the actual
      -- contents of the AST because that is tested in vscode/body_parser.
      local first_body_length = #parsed_snippets[1].body
      if first_body_length == 7 then
        assert.are_same(9, #parsed_snippets[2].body)
      elseif first_body_length == 9 then
        assert.are_same(7, #parsed_snippets[2].body)
      else
        -- This should never happen unless the parser fails.
        assert.is_false(true)
      end

      assert.are_same({}, parser_errors)
      assert.are_same(2, num_new_snippets)
    end)

    it("snippet with multiple triggers / prefixes", function()
      local data = {
        ["a function"] = {
          prefix = { "fn", "fun" },
          description = "function",
          body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
        },
      }
      parsed_snippets = {}
      local num_new_snippets = parser.parse(data, parsed_snippets, parser_errors)
      assert.are_same({}, parser_errors)
      assert.are_same(2, num_new_snippets)

      local first_trigger = parsed_snippets[1].trigger
      if first_trigger == "fn" then
        assert.are_same("fun", parsed_snippets[2].trigger)
      elseif first_trigger == "fun" then
        assert.are_same("fun", parsed_snippets[2].trigger)
      else
        -- This should never happen
        assert.is_false(true)
      end
    end)
  end)

  describe("should fail to parse", function()
    it("empty json", function()
      local data = {}
      local num_new_snippets = parser.parse(data, parsed_snippets, parser_errors)
      assert.are_same(0, num_new_snippets)
      assert.are_same({}, parsed_snippets)
      -- An empty input table doesn't count as a parser error as such
      assert.are_same({}, parser_errors)
    end)

    it("when snippet name is not a string", function()
      local data = {
        [111] = {
          body = "function ${1:name}($2)\n\t${3:-- code}\nend",
        },
      }
      local num_new_snippets = parser.parse(data, parsed_snippets, parser_errors)
      assert.are_same(0, num_new_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "snippet name must be a string, got number" }, parser_errors)
    end)

    it("when prefix is missing", function()
      local data = {
        ["fn"] = {
          body = "function ${1:name}($2)\n\t${3:-- code}\nend",
        },
      }
      local num_new_snippets = parser.parse(data, parsed_snippets, parser_errors)
      assert.are_same(0, num_new_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "prefix must be string or non-empty table, got nil" }, parser_errors)
    end)

    it("when description is not a string", function()
      local data = {
        ["fn"] = {
          prefix = "fn",
          description = { "some", "words" },
        },
      }
      local num_new_snippets = parser.parse(data, parsed_snippets, parser_errors)
      assert.are_same(0, num_new_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "description must be string or nil, got table" }, parser_errors)
    end)

    it("when body is not table", function()
      local data = {
        ["fn"] = {
          prefix = "fn",
          body = "for ${1:i}=${2:1},${3:10} do",
        },
      }
      local num_new_snippets = parser.parse(data, parsed_snippets, parser_errors)
      assert.are_same(0, num_new_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "body must be list, got string" }, parser_errors)
    end)

    it("when snippet syntax is invalid", function()
      local data = {
        ["fn"] = {
          prefix = "fn",
          body = { "for ${}" },
        },
      }
      local num_new_snippets = parser.parse(data, parsed_snippets, parser_errors)
      assert.are_same(0, num_new_snippets)
      assert.are_same(parsed_snippets, {})
      assert.ends_with("pattern [_a-zA-Z][_a-zA-Z0-9]* not matched at '}' (input string: 'for ${}')", parser_errors[1])
      assert.are_same(1, #parser_errors)
    end)
  end)
end)

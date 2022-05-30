local assertions = require("tests.custom_assertions")
local NodeType = require("snippet_converter.core.node_type")
local parser = require("snippet_converter.core.vscode.parser")

describe("VSCode parser", function()
  local data
  setup(function()
    assertions.register(assert)
    parser.get_lines = function()
      return data
    end
  end)

  local parsed_snippets, parser_errors
  before_each(function()
    parsed_snippets = {}
    parser_errors = {}
  end)

  describe("should parse", function()
    it("multiple snippets", function()
      data = {
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
      local num_new_snippets = parser.parse("/some/path.json", parsed_snippets, parser_errors)
      assert.is_true(type(parsed_snippets) == "table")

      assert.are_same({}, parser_errors)
      assert.are_same(2, num_new_snippets)

      local expected_fn = {
        name = "a function",
        trigger = "fn",
        description = "function",
        body_length = 7,
        path = "/some/path.json",
      }

      local expected_for = {
        name = "for",
        trigger = "for",
        description = nil,
        body_length = 9,
        path = "/some/path.json",
      }

      -- The pairs function does not specify the order in which the snippets will be traversed in,
      -- so we need to check both of the two possibilities. We don't check the actual
      -- contents of the AST because that is tested in vscode/body_parser.
      if parsed_snippets[1].trigger == "fn" then
        assert.matches_snippet(expected_fn, parsed_snippets[1], { ignore_line_nr = true })
        assert.matches_snippet(expected_for, parsed_snippets[2], { ignore_line_nr = true })
      elseif parsed_snippets[1].trigger == "for" then
        assert.matches_snippet(expected_for, parsed_snippets[1], { ignore_line_nr = true })
        assert.matches_snippet(expected_fn, parsed_snippets[2], { ignore_line_nr = true })
      else
        -- This should never happen unless the parser fails.
        assert.is_false(true)
      end
    end)

    it("snippet with multiple triggers / prefixes", function()
      data = {
        ["a function"] = {
          prefix = { "fn", "fun" },
          description = "function",
          body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
        },
      }
      parsed_snippets = {}
      local num_new_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
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

    it("snippet scope into table", function()
      data = {
        ["a function"] = {
          prefix = "fn",
          description = "function",
          scope = "javascript,typescript",
          body = "",
        },
      }
      parsed_snippets = {}
      local num_new_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
      assert.are_same({}, parser_errors)
      assert.are_same(1, num_new_snippets)
      assert.are_same({ "javascript", "typescript" }, parsed_snippets[1].scope)
    end)
  end)

  describe("should fail to parse", function()
    it("when snippet is not a table", function()
      data = {
        1,
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
      assert.are_same(0, num_snippets)
      assert.are_same({}, parsed_snippets)
      assert.are_same({ "snippet must be a table, got number" }, parser_errors)
    end)

    it("empty json", function()
      data = {}
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
      assert.are_same(0, num_snippets)
      assert.are_same({}, parsed_snippets)
      -- An empty input table doesn't count as a parser error as such
      assert.are_same({}, parser_errors)
    end)

    it("when snippet name is not a string", function()
      data = {
        [111] = {
          body = "function ${1:name}($2)\n\t${3:-- code}\nend",
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
      assert.are_same(0, num_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "snippet name must be a string, got number" }, parser_errors)
    end)

    it("when prefix is missing", function()
      data = {
        ["fn"] = {
          body = "function ${1:name}($2)\n\t${3:-- code}\nend",
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
      assert.are_same(0, num_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "prefix must be string or non-empty table, got nil" }, parser_errors)
    end)

    it("when description is not a string", function()
      data = {
        ["fn"] = {
          prefix = "fn",
          description = { "some", "words" },
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
      assert.are_same(0, num_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "description must be string or nil, got table" }, parser_errors)
    end)

    it("when scope is not a string", function()
      data = {
        ["fn"] = {
          prefix = "fn",
          scope = { "javascript", "typescript" },
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
      assert.are_same(0, num_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "scope must be string or nil, got table" }, parser_errors)
    end)

    it("when body is not table or string", function()
      data = {
        ["fn"] = {
          prefix = "fn",
          body = 999,
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
      assert.are_same(0, num_snippets)
      assert.are_same(parsed_snippets, {})
      assert.are_same({ "body must be list or string, got number" }, parser_errors)
    end)
  end)
end)

describe("VSCode parser (luasnip flavor)", function()
  local data
  setup(function()
    assertions.register(assert)
    parser.get_lines = function()
      return data
    end
  end)

  local parsed_snippets, parser_errors
  before_each(function()
    parsed_snippets = {}
    parser_errors = {}
  end)
  describe("should parse", function()
    it("snippet with luasnip key", function()
      data = {
        fn = {
          prefix = "fn",
          body = "text",
          luasnip = {
            autotrigger = true,
            priority = 100,
          },
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors, { flavor = "luasnip" })
      assert.are_same(1, num_snippets)
      assert.are_same({
        {
          name = "fn",
          trigger = "fn",
          path = "some/path",
          body = { { type = NodeType.TEXT, text = "text" } },
          autotrigger = true,
          priority = 100,
        },
      }, parsed_snippets)
      assert.are_same({}, parser_errors)
    end)
  end)

  describe("should fail to parse", function()
    -- Check that test from parent parser works
    it("when snippet is not a table", function()
      data = {
        1,
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors, { flavor = "luasnip" })
      assert.are_same(0, num_snippets)
      assert.are_same({}, parsed_snippets)
      assert.are_same({ "snippet must be a table, got number" }, parser_errors)
    end)

    it("when luasnip is not a table", function()
      data = {
        fn = {
          prefix = "fn",
          body = "body",
          luasnip = "",
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors, { flavor = "luasnip" })
      assert.are_same(0, num_snippets)
      assert.are_same({}, parsed_snippets)
      assert.are_same({ "luasnip must be a table, got string" }, parser_errors)
    end)

    it("when luasnip.autotrigger is not a boolean", function()
      data = {
        fn = {
          prefix = "fn",
          body = "body",
          luasnip = {
            autotrigger = "",
          },
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors, { flavor = "luasnip" })
      assert.are_same(0, num_snippets)
      assert.are_same({}, parsed_snippets)
      assert.are_same({ "luasnip.autotrigger must be a boolean, got string" }, parser_errors)
    end)

    it("when luasnip.priority is not a number", function()
      data = {
        fn = {
          prefix = "fn",
          body = "body",
          luasnip = {
            priority = "",
          },
        },
      }
      local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors, { flavor = "luasnip" })
      assert.are_same(0, num_snippets)
      assert.are_same({}, parsed_snippets)
      assert.are_same({ "luasnip.priority must be a number, got string" }, parser_errors)
    end)
  end)
end)

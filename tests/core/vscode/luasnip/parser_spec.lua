local assertions = require("tests.custom_assertions")
local vscode_parser = require("snippet_converter.core.vscode.parser")
local parser = require("snippet_converter.core.vscode.luasnip.parser")

describe("VSCode_LuaSnip parser should fail to parse", function()
  local data
  setup(function()
    assertions.register(assert)
    vscode_parser.get_lines = function()
      return data
    end
  end)

  local parsed_snippets, parser_errors
  before_each(function()
    parsed_snippets = {}
    parser_errors = {}
  end)

  -- Check that test from parent parser works
  it("when snippet is not a table", function()
    data = {
      1,
    }
    local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
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
    local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
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
    local num_snippets = parser.parse("some/path", parsed_snippets, parser_errors)
    assert.are_same(0, num_snippets)
    assert.are_same({}, parsed_snippets)
    assert.are_same({ "luasnip.autotrigger must be a boolean, got string" }, parser_errors)
  end)
end)

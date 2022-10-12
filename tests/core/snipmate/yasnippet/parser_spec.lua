local assertions = require("tests.custom_assertions")
local parser = require("snippet_converter.core.snipmate.yasnippet.parser")

describe("YASnippet parser", function()
  setup(function()
    assertions.register(assert)
  end)

  local parsed_snippets, parser_errors
  before_each(function()
    parsed_snippets = {}
    parser_errors = {}
  end)

  describe("should parse", function()
    it("snippet", function()
      local lines = vim.split(
        [[
# -*- mode: snippet -*-
# name: if description
# key: if
# A comment
# --
if $1 then
	$0
end]],
        "\n"
      )
      parser.get_lines = function(_)
        return lines
      end

      parsed_snippets = {}
      local num_snippets = parser.parse("/some/snippet/path.snippets", parsed_snippets, parser_errors)

      assert.are_same({}, parser_errors)
      assert.are_same(1, num_snippets)

      local expected_if = {
        trigger = "if",
        description = "if description",
        body_length = 5,
        path = "/some/snippet/path.snippets",
        line_nr = 6,
      }
      assert.matches_snippet(expected_if, parsed_snippets[1])
    end)

    it("snippet with comment in body", function()
      local lines = vim.split(
        [[
# key: if
# --
# -*- a comment $1 -*-]],
        "\n"
      )
      parser.get_lines = function(_)
        return lines
      end

      parsed_snippets = {}
      local num_snippets = parser.parse("/some/snippet/path.snippets", parsed_snippets, parser_errors)

      assert.are_same({}, parser_errors)
      assert.are_same(1, num_snippets)

      local expected_if = {
        trigger = "if",
        -- Two text nodes and one tabstop node
        body_length = 3,
        path = "/some/snippet/path.snippets",
        line_nr = 3,
      }
      assert.matches_snippet(expected_if, parsed_snippets[1])
    end)
  end)

  describe("should not parse", function()
    it([[when type is "command"]], function()
      local lines = vim.split(
        [[
# name: if description
# key: if
# type: command
# --
if $1 then
	$0
end]],
        "\n"
      )
      parser.get_lines = function(_)
        return lines
      end

      parsed_snippets = {}
      local num_snippets = parser.parse("/some/snippet/path.snippets", parsed_snippets, parser_errors)

      assert.are_same(
        { { line_nr = 5, msg = [[unsupported type "command"]], path = "/some/snippet/path.snippets" } },
        parser_errors
      )
      assert.are_same(0, num_snippets)
    end)
  end)

  it("should use filetype as trigger when key is missing", function()
    local lines = vim.split(
      [[
# type: snippet
# --
if $1 then
	$0
end]],
      "\n"
    )
    parser.get_lines = function(_)
      return lines
    end

    parsed_snippets = {}
    local num_snippets = parser.parse("/some/snippet/path", parsed_snippets, parser_errors)

    local expected_snippet = {
      trigger = "path",
      -- Two text nodes and one tabstop node
      body_length = 5,
      path = "/some/snippet/path",
      line_nr = 3,
    }
    assert.matches_snippet(expected_snippet, parsed_snippets[1])
    assert.are_same(1, num_snippets)
  end)
end)

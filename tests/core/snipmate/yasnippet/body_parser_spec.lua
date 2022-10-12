local parser = require("snippet_converter.core.snipmate.yasnippet.body_parser")
local NodeType = require("snippet_converter.core.node_type")

describe("YASnippet parser", function()
  it("should parse tabstop and placeholder", function()
    local input = "local ${1:name} = function($2)"
    local expected = {
      { text = "local ", type = NodeType.TEXT },
      {
        int = "1",
        any = { { text = "name", type = NodeType.TEXT } },
        type = NodeType.PLACEHOLDER,
      },
      { text = " = function(", type = NodeType.TEXT },
      { int = "2", type = NodeType.TABSTOP },
      { text = ")", type = NodeType.TEXT },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should handle escaped chars", function()
    -- Normal characters like 'b' can also be escaped (\b is parsed as b)
    local input = [[\`\{\$\\${1:a\bcdef\n}]]
    local expected = {
      { text = [[`{$\]], type = NodeType.TEXT },
      {
        int = "1",
        any = { { text = "abcdefn", type = NodeType.TEXT } },
        type = NodeType.PLACEHOLDER,
      },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should handle escaped '}' in placeholder", function()
    local input = [[${1:a\}b}]]
    local expected = {
      {
        int = "1",
        any = { { text = "a}b", type = NodeType.TEXT } },
        type = NodeType.PLACEHOLDER,
      },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should parse Emacs-Lisp code", function()
    local input = [[`yas-selected-text`]]
    local expected = { { code = "yas-selected-text", type = NodeType.EMACS_LISP_CODE } }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should parse placeholder with nested tabstop", function()
    local input = [[${2:{$3}}]]
    local expected = {
      {
        type = NodeType.PLACEHOLDER,
        int = "2",
        any = {
          { type = NodeType.TEXT, text = "{" },
          { type = NodeType.TABSTOP, int = "3" },
          { type = NodeType.TEXT, text = "}" },
        },
      },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should parse placeholder with transformation", function()
    local input = [["${1:$$(upcase yas-text)}]]
    local expected = {
      { type = NodeType.TEXT, text = [["]] },
      {
        type = NodeType.TABSTOP,
        int = "1",
        transform = {
          type = NodeType.TRANSFORM,
          replacement = "upcase yas-text",
        },
      },
    }
    assert.are_same(expected, parser.parse(input))
  end)
end)

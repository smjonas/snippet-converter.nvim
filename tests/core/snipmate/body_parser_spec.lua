local parser = require("snippet_converter.core.snipmate.body_parser")
local NodeType = require("snippet_converter.core.node_type")

describe("SnipMate body parser", function()
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
    -- Normal characters like 'b' can also be escaped (\b is output as b)
    local input = [[\`\{\$\\${1:a\bc\}def\n}]]
    local expected = {
      { text = [[`{$\]], type = NodeType.TEXT },
      {
        int = "1",
        any = { { text = "abc}defn", type = NodeType.TEXT } },
        type = NodeType.PLACEHOLDER,
      },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should parse vimscript code", function()
    local input = [[`echo "test"`]]
    local expected = { { code = [[echo "test"]], type = NodeType.VIMSCRIPT_CODE } }
    assert.are_same(expected, parser.parse(input))
  end)
end)

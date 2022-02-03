local parser = require("snippet_converter.core.ultisnips.body_parser")
local NodeType = require("snippet_converter.core.node_type")

describe("UltiSnips body parser", function()
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

  it("should parse choice element", function()
    local input = "${0|🠂,⇨|}"
    local expected = {
      { int = "0", text = { "🠂", "⇨" }, type = NodeType.CHOICE },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should handle escaped chars in text element", function()
    local input = [[\`\{\$\\]]
    local expected = { { text = [[`{$\]], type = NodeType.TEXT } }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should parse python code", function()
    local input = [[`!p print("hello world")`]]
    local expected = { { code = [[print("hello world")]], type = NodeType.PYTHON_CODE } }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should parse transformation", function()
    local input = [[${1/\w+\s*/\u$0/}]]
    local expected = {
      {
        int = "1",
        transform = {
          regex = [[\w+\s*]],
          replacement = [[\u$0]],
          options = "",
          type = NodeType.TRANSFORM,
        },
        type = NodeType.TABSTOP,
      },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should parse placeholder with multiple nested nodes", function()
    local input = [[${3:else success(${4:ok, err})} end)]]
    local expected = {
      {
        int = "3",
        any = {
          { text = "else success(", type = NodeType.TEXT },
          {
            int = "4",
            any = { { text = "ok, err", type = NodeType.TEXT } },
            type = NodeType.PLACEHOLDER,
          },
          { text = ")", type = NodeType.TEXT },
        },
        type = NodeType.PLACEHOLDER,
      },
      {
        text = " end)",
        type = NodeType.TEXT,
      },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  -- TODO: how are unescaped chars handled?
end)

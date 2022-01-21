local parser = require("snippet_converter.ultisnips.body_parser")
local NodeType = require("snippet_converter.base.node_type")

describe("UltiSnips body parser", function()
  it("should parse tabstop and placeholder", function()
    local input = "local ${1:name} = function($2)"
    local actual = parser.parse(input)
    local expected = {
      { text = "local " },
      { int = "1", any = { text = "name" }, type = NodeType.PLACEHOLDER },
      { text = " = function(" },
      { int = "2", type = NodeType.TABSTOP },
      { text = ")" },
    }
    assert.are_same(expected, actual)
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
    local expected = { { text = [[`{$\]] } }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should parse python code", function()
    local input = [[`!p print("hello world")`]]
    local expected = { { code = [[print("hello world")]], type = NodeType.PYTHON_CODE } }
    assert.are_same(expected, parser.parse(input))
  end)

end)

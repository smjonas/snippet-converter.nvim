local parser = require("snippet_converter.core.vscode.body_parser")
local NodeType = require("snippet_converter.core.node_type")

describe("VSCode body parser", function()
  it("should parse tabstop and placeholder", function()
    local input = "local ${1:name} = function($2)"
    local actual = parser.parse(input)
    local expected = {
      { text = "local " },
      { int = "1", any = { type = NodeType.TEXT, text = "name" }, type = NodeType.PLACEHOLDER },
      { text = " = function(" },
      { int = "2", type = NodeType.TABSTOP },
      { text = ")" },
    }
    assert.are_same(expected, actual)
  end)

  it("should parse variable with transform", function()
    local input = "${TM_FILENAME/(.*)/${1:/upcase}/}"
    local actual = parser.parse(input)
    local expected = {
      {
        var = "TM_FILENAME",
        transform = {
          regex = "(.*)",
          format_or_text = {
            { int = "1", format_modifier = "upcase", type = NodeType.FORMAT },
          },
          options = "",
        },
        type = NodeType.VARIABLE,
      },
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

  it("should handle escaped chars in choice element", function()
    local input = [[${0|\$,\},\\,\,,\||}]]
    local expected = {
      { int = "0", text = { "$", "}", [[\]], ",", "|" }, type = NodeType.CHOICE },
    }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should handle escaped chars in text element", function()
    local input = [[\\\$\}]]
    local expected = { { type = NodeType.TEXT, text = [[\$}]] } }
    assert.are_same(expected, parser.parse(input))
  end)

  it("should not run into infinite loop but cause error", function()
    local input = [[${0|\|||}]]
    assert.has.errors(function()
      parser.parse(input)
    end)
  end)
end)

local parser = require "snippet_converter.vscode.body_parser2"

describe("VSCode body parser", function()
  it("should parse tabstop and placeholder", function()
    local input = "local ${1:name} = function($2)"
    local actual = parser.parse(input)
    local expected = {
      { "local ", tag = "text" },
      { "1", { "name", tag = "text" }, tag = "placeholder" },
      { " = function(", tag = "text" },
      { "2", tag = "tabstop" },
      { ")", tag = "text" },
    }
    assert.are_same(expected, actual)
  end)

  it("should parse choice element", function()
    local input = "
  end)

  it("should handle escaped chars", function()
    local input = [[local \${1:name} = function($2)]]
    local actual = parser.parse(input)
    local expected = {
      { "local ", tag = "text" },
      { "1", { "name", tag = "text" }, tag = "placeholder" },
      { " = function(", tag = "text" },
      { "2", tag = "tabstop" },
      { ")", tag = "text" },
    }
    assert.are_same(expected, actual)
  end)
end)

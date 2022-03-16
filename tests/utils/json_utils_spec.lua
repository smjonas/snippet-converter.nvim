local json_utils = require("snippet_converter.utils.json_utils").new()

describe("JSON utils should stringify", function()
  it("empty array", function()
    local expected = "[]"
    assert.are_same(expected, json_utils:stringify {})
  end)

  it("table with simple string key + value pair", function()
    local expected = [[
{
  "key": "value"
}]]
    local input = {
      key = "value",
    }
    assert.are_same(expected, json_utils:stringify(input))
  end)

  it("table with multiple key value pairs (default sort order)", function()
    local expected = [[
{
  "keyA": "valueA",
  "keyB": "valueB"
}]]
    local input = { keyA = "valueA", keyB = "valueB" }
    assert.are_same(expected, json_utils:stringify(input))
  end)

  it("table with multiple key value pairs (custom sort order)", function()
    local expected = [[
{
  "keyB": "valueB",
  "keyA": "valueA"
}]]
    local input = { keyA = "valueA", keyB = "valueB" }
    assert.are_same(
      expected,
      json_utils:stringify(input, function(a, b)
        return a:lower() > b:lower()
      end)
    )
  end)

  it("array", function()
    local expected = [=[
[
  "a",
  "b",
  "c"
]]=]
    local input = { "a", "b", "c" }
    assert.are_same(expected, json_utils:stringify(input))
  end)

  it("table with inner array as value", function()
    local expected = [[
{
  "key": [
    "v1",
    "v2"
  ]
}]]
    local input = { key = { "v1", "v2" } }
    assert.are_same(expected, json_utils:stringify(input))
  end)

  it("table with nested table as value", function()
    local expected = [[
{
  "contributes": {
    "snippets": "value"
  }
}]]
    local input = { contributes = { snippets = "value" } }
    assert.are_same(expected, json_utils:stringify(input))
  end)

  it("more complex scenario", function()
    local input = {
      contributes = {
        snippets = {
          {
            language = { "plaintext", "markdown", "tex", "html", "global" },
            path = "./snippets/global.json",
          },
          {
            language = "c",
            path = "./snippets/c.json",
          },
        },
      },
    }
    local expected = [[
{
  "contributes": {
    "snippets": [
      {
        "language": [
          "plaintext",
          "markdown",
          "tex",
          "html",
          "global"
        ],
        "path": "./snippets/global.json"
      },
      {
        "language": "c",
        "path": "./snippets/c.json"
      }
    ]
  }
}]]
    assert.are_same(
      expected,
      json_utils:stringify(input, function(key, _)
        return key == "language"
      end)
    )
  end)


end)

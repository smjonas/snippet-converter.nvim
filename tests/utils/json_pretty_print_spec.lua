local json = require("snippet_converter.utils.json_utils")

describe("JSON utils should pretty-print", function()
  it("empty table", function()
    local expected = "{}"
    assert.are_same(expected, json:pretty_print {})
  end)

  it("nil value", function()
    local expected = "null"
    assert.are_same(expected, json:pretty_print(nil))
  end)

  it("numbers", function()
    local expected = [[
{
  "a": -123,
  "b": 456.78
}]]
    local input = {
      a = -123,
      b = 456.78,
    }
    assert.are_same(expected, json:pretty_print(input))
  end)

  it("table with simple string key + value pair", function()
    local expected = [[
{
  "key": "value"
}]]
    local input = {
      key = "value",
    }
    assert.are_same(expected, json:pretty_print(input))
  end)

  it("table with multiple key value pairs (default sort order)", function()
    local expected = [[
{
  "keyA": "valueA",
  "keyB": "valueB"
}]]
    local input = { keyA = "valueA", keyB = "valueB" }
    assert.are_same(expected, json:pretty_print(input))
  end)

  it("table with multiple key value pairs (custom sort order)", function()
    local expected = [[
{
  "key3": "value3",
  "key1": "value1",
  "key2": "value2"
}]]
    local input = { key1 = "value1", key2 = "value2", key3 = "value3" }
    local keys_order = { "key3", "key1", "key2" }
    assert.are_same(expected, json:pretty_print(input, keys_order))
  end)

  it("array", function()
    local expected = [=[
[
  "a",
  "b",
  "c"
]]=]
    local input = { "a", "b", "c" }
    assert.are_same(expected, json:pretty_print(input))
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
    assert.are_same(expected, json:pretty_print(input))
  end)

  it("table with nested table as value", function()
    local expected = [[
{
  "contributes": {
    "snippets": "value"
  }
}]]
    local input = { contributes = { snippets = "value" } }
    assert.are_same(expected, json:pretty_print(input))
  end)

  it("should escape special characters", function()
    local input = {
      key = '}$\\\\"\a\b\f\n\r\t\v',
    }
    local expected = [[
{
  "key": "\}\$\\\\\"\a\b\f\n\r\t\v"
}]]
    assert.are_same(expected, json:pretty_print(input, nil, true))
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
    assert.are_same(expected, json:pretty_print(input, { "language" }))
  end)
end)

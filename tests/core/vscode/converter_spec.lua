local converter = require("snippet_converter.core.vscode.converter")

describe("VSCode converter", function()
  describe("should convert snippet", function()
    it("(basic)", function()
      local snippet = {
        trigger = "fn",
        description = "function",
        body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
      }
      local actual = converter.convert(snippet)
      local expected = {
        name = "function",
        prefix = { "fn" },
        description = "function",
        body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
      }
      assert.are_same(expected, actual)
    end)
  end)

  it("without description => use trigger for name", function()
    local snippet = {
      trigger = "some trigger",
      body = { "body" },
    }
    local actual = converter.convert(snippet)
    local expected = {
      name = "some trigger",
      prefix = { "some trigger" },
      body = { "body" },
    }
    assert.are_same(expected, actual)
  end)
end)

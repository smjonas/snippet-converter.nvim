local converter = require("snippet_converter.core.vscode.luasnip.converter")

describe("VSCode_LuaSnip converter ", function()
  it("should convert autotrigger option", function()
    local snippet = {
      trigger = "fn",
      body = {},
      options = "iA",
      luasnip = {
        autotrigger = false,
      },
    }
    local actual = converter.convert(snippet)
    local expected = {
      trigger = "fn",
      body = "",
      -- Original key is not modified
      options = "iA",
      luasnip = {
        autotrigger = true,
      },
    }
    assert.are_same(expected, actual)
  end)
end)

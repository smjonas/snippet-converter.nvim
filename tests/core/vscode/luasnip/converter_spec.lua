local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.vscode.luasnip.converter")

describe("VSCode_LuaSnip converter ", function()
  it("should not create empty luasnip table", function()
    local snippet = {
      trigger = "fn",
      body = {},
    }
    local actual = converter.convert(snippet)
    local expected = {
      trigger = "fn",
      body = "",
    }
    assert.are_same(expected, actual)
  end)

  it("should convert autotrigger key from options", function()
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
      -- Original key is not modified (but ignored during export)
      options = "iA",
      luasnip = {
        autotrigger = true,
      },
    }
    assert.are_same(expected, actual)
  end)

  it("should convert autotrigger flag", function()
    local snippet = {
      trigger = "fn",
      body = {},
      autotrigger = true,
    }
    local actual = converter.convert(snippet)
    local expected = {
      trigger = "fn",
      body = "",
      -- Original key is not modified
      autotrigger = true,
      luasnip = {
        autotrigger = true,
      },
    }
    assert.are_same(expected, actual)
  end)

  it("should convert priority", function()
    local snippet = {
      trigger = "fn",
      body = { { type = NodeType.TEXT, text = "txt" } },
      priority = 100,
    }
    local actual = converter.convert(snippet)
    local expected = {
      trigger = "fn",
      body = "txt",
      -- Original key is not modified
      priority = 100,
      luasnip = {
        priority = 100,
      },
    }
    assert.are_same(expected, actual)
  end)
end)

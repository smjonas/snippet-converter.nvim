local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.vscode.vsnip.converter")

describe("vsnip converter should", function()
  it("convert Vimscript code", function()
    local snippet = {
      name = "user",
      trigger = "username",
      body = {
        { type = NodeType.VIMSCRIPT_CODE, code = "\\$USER" },
      },
    }
    local actual = converter.convert(snippet)
    local expected = {
      name = "user",
      trigger = "username",
      body = "${VIM:\\$USER}",
    }
    assert.are_same(expected, actual)
  end)

  it("escape $ in text node #16", function()
    local snippet = {
      trigger = "fn",
      body = {
        { type = NodeType.TEXT, text = "$option" },
      },
    }
    local expected = {
      trigger = "fn",
      body = "\\$option",
    }

    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)
end)

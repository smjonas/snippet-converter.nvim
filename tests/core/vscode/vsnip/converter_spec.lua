local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.vscode.vsnip.converter")

describe("vsnip converter", function()
  it("should convert VimScript code", function()
      local snippet = {
        name = "user",
        trigger = "username",
        body = {
          { type = NodeType.VIMSCRIPT_CODE, code = "\\$USER" },
        },
      }
      local actual = converter.convert(snippet)
      -- TODO: check escaping of $ in vsnip!
      local expected = [[
  "user": {
    "prefix": "username",
    "body": "${VIM:$USER}"
  }]]
      assert.are_same(expected, actual)
    end)
end)

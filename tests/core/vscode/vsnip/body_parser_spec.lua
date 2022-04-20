local parser = require("snippet_converter.core.vscode.vsnip.body_parser")
local NodeType = require("snippet_converter.core.node_type")

describe("vsnip body parser", function()
  it("should parse vimscript code", function()
    local input = [[${VIM:\\$USER}]]
    local ok, actual = parser:parse(input)
    local expected = {
      { type = NodeType.VIMSCRIPT_CODE, code = "\\$USER" },
    }
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("should not parse variable with transform", function()
    local input = "${TM_FILENAME/(.*)/${1:/upcase}/}"
    local ok, actual = parser:parse(input)
    local expected =
      [[transform in variable node is not supported by vim-vsnip at '/(.*)/${1:/upcase}/}' (input line: '${TM_FILENAME/(.*)/${1:/upcase}/}')]]
    assert.is_false(ok)
    assert.are_same(expected, actual)
  end)
end)

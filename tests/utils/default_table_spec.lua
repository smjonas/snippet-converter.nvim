local make_default_table = require("snippet_converter.utils.default_table").new

describe("Default table", function()
  it("should set to empty table if key does not exist", function()
    local tbl = {}
    make_default_table(tbl, "some key for which no value exists")["new_key"] = 1
    assert.are_same({ new_key = 1 }, tbl["some key for which no value exists"])
  end)
end)

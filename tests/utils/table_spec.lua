local utils = require("snippet_converter.utils.table")

describe("Default table", function()
  it("should set to empty table if key does not exist", function()
    local tbl = {}
    utils.make_default_table(tbl, "some key for which no value exists")["new_key"] = 1
    assert.are_same({ new_key = 1 }, tbl["some key for which no value exists"])
  end)
end)

describe("Compact", function()
  it("should remove gaps from array", function()
    local arr = { "A", "B", "C", "D" }
    utils.compact(arr, { false, true, true, false })
    assert.are_same({ "B", "C" }, arr)
  end)
end)

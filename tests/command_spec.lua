local command = require("snippet_converter.command")

describe("command should", function()
  it("validate args (template names + option)", function()
    local args = { "matching_name1", "matching_name2", "--headless=true" }
    local config = {
      templates = {
        { name = "matching_name1" },
        { name = "non_matching_name" },
        { name = "matching_name2" },
      },
    }
    local expected = {
      templates = { { name = "matching_name1" }, { name = "matching_name2" } },
      opts = { headless = true },
    }
    local ok, actual = command.validate_args(args, config)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)
end)

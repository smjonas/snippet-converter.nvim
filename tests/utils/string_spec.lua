local string = require("snippet_converter.utils.string")

describe("Dedent", function()
  it("should work", function()
    local actual = string.dedent([[
        snippet test
        	hey

        	line
      ]])
    local expected = "snippet test\n\they\n\n\tline"
    assert.are_same(expected, actual)
  end)

  it("should raise error on inconsistent indentation", function()
    local stubbed_notify = stub.new(vim, "notify")
    local actual = string.dedent([[
      snippet test
      	hey

    line
    ]])
    assert.is_nil(actual)
    assert.stub(stubbed_notify).was.called_with(
      match.is_same("[snippet-converter.nvim] helper.dedent: inconsistent indentation"),
      match.is_same(vim.log.levels.ERROR)
    )
  end)
end)

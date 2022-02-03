local converter = require("snippet_converter.core.snipmate.converter")

describe("SnipMate converter", function()
  describe("should convert snippet", function()
    it("(basic)", function()
      local snippet = {
        trigger = "fn",
        description = "a function",
        body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
      }
      local actual = converter.convert(snippet, "")
      local expected = [[
snippet fn a function
	function ${1:name}($2)
		${3:-- code}
	end]]
      assert.are_same(expected, actual)
    end)
  end)

  describe("should not convert snippet", function()
    it("if trigger contains multiple words", function()
      local snippet = {
        trigger = [["hello world"]],
        body = { "body" },
      }
      assert.is_nil(converter.convert(snippet, ""))
    end)
  end)
end)

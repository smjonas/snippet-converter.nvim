local converter = require("snippet_converter.converters.ultisnips")

describe("converter for UltiSnips", function()
  describe("should convert snippet", function()
    it("(standard)", function()
      local snippet = {
        trigger = "fn",
        description = "function",
        body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
      }
      local actual = converter.convert(snippet)
      local expected = [[
snippet fn "function"
function ${1:name}($2)
	${3:-- code}
end
endsnippet]]
      assert.are_same(expected, actual)
    end)

    it("with multi-word trigger", function()
      local snippet = {
        trigger = "several words",
        body = { "body" },
      }
      local actual = converter.convert(snippet)
      local expected = [[
snippet "several words"
body
endsnippet]]
      assert.are_same(expected, actual)
    end)

    it("with literal quote in trigger", function()
      local snippet = {
        trigger = [[some "quotes" ]],
        body = { "body" },
      }
      local actual = converter.convert(snippet)
      local expected = [[
snippet !some "quotes" !
body
endsnippet]]
      assert.are_same(expected, actual)
    end)
  end)
end)

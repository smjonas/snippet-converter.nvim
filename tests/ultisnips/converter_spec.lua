local NodeType = require("snippet_converter.base.node_type")
local converter = require("snippet_converter.ultisnips.converter")

describe("UltiSnips converter", function()
  describe("should convert snippet", function()
    it("(basic)", function()
      local snippet = {
        trigger = "fn",
        description = "function",
        -- AST of snippet body
        body = {
          { type = NodeType.TEXT, text = "function " },
          {
            type = NodeType.PLACEHOLDER,
            int = "1",
            any = { type = NodeType.TEXT, text = "name" },
          },
          { type = NodeType.TEXT, text = "(" },
          { type = NodeType.TABSTOP, int = "2" },
          { type = NodeType.TEXT, text = ")\n\t" },
          {
            type = NodeType.PLACEHOLDER,
            int = "3",
            any = { type = NodeType.TEXT, text = "-- code" },
          },
          { type = NodeType.TEXT, text = "\nend" },
        },
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
        body = { { type = NodeType.TEXT, text = "body" } },
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
        body = { { type = NodeType.TEXT, text = "body" } },
      }
      local actual = converter.convert(snippet)
      local expected = [[
snippet !some "quotes" !
body
endsnippet]]
      assert.are_same(expected, actual)
    end)
  end)

  describe("cannot convert to other format", function()
    it("if body contains interpolation code", function()
      local snippet = {
        trigger = "indent",
        body = { [[Indent is: `v! indent(".")`]] },
      }
      assert.is_false(converter.can_convert(snippet, "any engine"))
    end)
  end)

  describe("can convert to other format", function()
    it("if body does not contain interpolation code", function()
      local snippet = {
        trigger = "test",
        body = { "`hey" },
      }
      assert.is_true(converter.can_convert(snippet, "any engine"))
    end)
  end)

  describe("should convert body from VSCode", function()
    it("with variable", function()
      local snippet = {
        trigger = "test",
        body = {
          {
            type = NodeType.TEXT,
            text = "current path: ",
          },
          {
            type = NodeType.VARIABLE,
            var = "TM_FILENAME",
          },
        },
      }
      local actual = converter.convert(snippet)
      assert.are_same(
        [[
snippet test
current path: `!v expand('%:t')`
endsnippet]],
        actual
      )
    end)

    it("with nested placeholder", function()
      local snippet = {
        trigger = "test",
        body = {
          {
            type = NodeType.PLACEHOLDER,
            int = "1",
            any = {
              type = NodeType.TABSTOP,
              int = "2",
            },
          },
        },
      }
      local actual = converter.convert(snippet)
      assert.are_same(
        [[
snippet test
${1:$2}
endsnippet]],
        actual
      )
    end)
  end)
end)

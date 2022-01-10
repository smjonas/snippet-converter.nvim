local NodeType = require "snippet_converter.base.node_type"
local converter = require "snippet_converter.ultisnips.converter"

describe("UltiSnips converter", function()
  --   describe("should convert snippet", function()
  --     it("(basic)", function()
  --       local snippet = {
  --         trigger = "fn",
  --         description = "function",
  --         body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
  --       }
  --       local actual = converter.convert(snippet)
  --       local expected = [[
  -- snippet fn "function"
  -- function ${1:name}($2)
  -- 	${3:-- code}
  -- end
  -- endsnippet]]
  --       assert.are_same(expected, actual)
  --     end)

  --     it("with multi-word trigger", function()
  --       local snippet = {
  --         trigger = "several words",
  --         body = { "body" },
  --       }
  --       local actual = converter.convert(snippet)
  --       local expected = [[
  -- snippet "several words"
  -- body
  -- endsnippet]]
  --       assert.are_same(expected, actual)
  --     end)

  --     it("with literal quote in trigger", function()
  --       local snippet = {
  --         trigger = [[some "quotes" ]],
  --         body = { "body" },
  --       }
  --       local actual = converter.convert(snippet)
  --       local expected = [[
  -- snippet !some "quotes" !
  -- body
  -- endsnippet]]
  --       assert.are_same(expected, actual)
  --     end)
  --   end)

  --   describe("cannot convert to other format", function()
  --     it("if body contains interpolation code", function()
  --       local snippet = {
  --         trigger = "indent",
  --         body = { [[Indent is: `v! indent(".")`]] },
  --       }
  --       assert.is_false(converter.can_convert(snippet, "any engine"))
  --     end)
  --   end)

  --   describe("can convert to other format", function()
  --     it("if body does not contain interpolation code", function()
  --       local snippet = {
  --         trigger = "test",
  --         body = { "`hey" },
  --       }
  --       assert.is_true(converter.can_convert(snippet, "any engine"))
  --     end)
  --   end)

  describe("should convert body", function()
    it("from VSCode snippet", function()
      local snippet = {
        trigger = "test",
        body = {
          {
            var = "TM_FILENAME",
            any = {
              text = "some text",
            },
            tag = NodeType.VARIABLE,
          },
        },
      }
      local actual = converter.convert(snippet)
      print(actual)
    end)
  end)
end)

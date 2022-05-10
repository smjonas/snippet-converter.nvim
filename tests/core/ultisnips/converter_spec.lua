local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.ultisnips.converter")

describe("UltiSnips converter should", function()
  it("convert basic snippet", function()
    local snippet = {
      trigger = "fn",
      description = "function",
      -- AST of snippet body
      body = {
        { type = NodeType.TEXT, text = "function " },
        {
          type = NodeType.PLACEHOLDER,
          int = "1",
          any = { { type = NodeType.TEXT, text = "name" } },
        },
        { type = NodeType.TEXT, text = "(" },
        { type = NodeType.TABSTOP, int = "2" },
        { type = NodeType.TEXT, text = ")\n\t" },
        {
          type = NodeType.PLACEHOLDER,
          int = "3",
          any = { { type = NodeType.TEXT, text = "-- code" } },
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

  it("convert snippet with multi-word trigger", function()
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

  it("convert snippet with transformation in tabstop", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          type = NodeType.TABSTOP,
          int = "1",
          transform = {
            type = NodeType.TRANSFORM,
            regex = "foo",
            replacement = "bar",
            options = "g",
          },
        },
      },
    }
    local actual = converter.convert(snippet)
    local expected = [[
snippet fn
${1/foo/bar/g}
endsnippet]]
    assert.are_same(expected, actual)
  end)

  it("handle literal quote in trigger", function()
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

  it("convert choice node", function()
    local snippet = {
      trigger = "fn",
      body = {
        { type = NodeType.CHOICE, int = "1", text = { "a", "b", "c" } },
        { type = NodeType.CHOICE, int = "2", text = { "a" } },
      },
    }
    local expected = [[
snippet fn
${1|a,b,c|}${2|a|}
endsnippet]]
    local actual = converter.convert(snippet)
    assert.are_same(expected, actual)
  end)

  it("escape ambiguous chars", function()
    local snippet = {
      trigger = "fn",
      body = { { type = NodeType.TEXT, text = "$1 ${1:abc} `code`" } },
    }
    local actual = converter.convert(snippet)
    local expected = [[
snippet fn
\$1 \${1:abc} \`code\`
endsnippet]]
    assert.are_same(expected, actual)
  end)

  it("convert snippet with transform", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          int = "1",
          transform = {
            regex = [[\w+\s*]],
            replacement = [[\u$0]],
            options = "",
            type = NodeType.TRANSFORM,
          },
          type = NodeType.TABSTOP,
        },
      },
    }
    local actual = converter.convert(snippet)
    -- TODO: UltiSnips -> VSCode: correctly convert regex
    local expected = [[
snippet fn
${1/\w+\s*/\u$0/}
endsnippet]]
    assert.are_same(expected, actual)
  end)

  describe("convert body from VSCode", function()
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
              {
                type = NodeType.TABSTOP,
                int = "2",
              },
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

  describe("VSCode_LuaSnip snippet", function()
    it("with luasnip.autotrigger key and existing options", function()
      local snippet = {
        trigger = "test",
        body = {},
        options = "i",
        luasnip = {
          autotrigger = true,
        },
      }
      local actual = converter.convert(snippet)
      assert.are_same(
        [[
snippet test iA

endsnippet]],
        actual
      )
      -- TODO: ^ there should not be a new line here
    end)

    it("with luasnip.autotrigger key and no existing options", function()
      local snippet = {
        trigger = "test",
        body = {},
        luasnip = {
          autotrigger = true,
        },
      }
      local actual = converter.convert(snippet)
      assert.are_same(
        [[
snippet test A

endsnippet]],
        actual
      )
      -- TODO: ^ there should not be a new line here
    end)

  end)
end)

local NodeType = require("snippet_converter.core.node_type")
local converter = require("snippet_converter.core.snipmate.converter")

describe("SnipMate converter should", function()
  it("convert basic snippet", function()
    local snippet = {
      trigger = "fn",
      description = "a function",
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
snippet fn a function
	function ${1:name}($2)
		${3:-- code}
	end]]
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
	${1/foo/bar/g}]]
    assert.are_same(expected, actual)
  end)

  it("convert Vimscript code", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          type = NodeType.VIMSCRIPT_CODE,
          code = [[strftime("%H:%M")]],
        },
      },
    }
    local actual = converter.convert(snippet)
    local expected = [[
snippet fn
	`strftime("%H:%M")`]]
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
	\$1 \${1:abc} \`code\`]]
    assert.are_same(expected, actual)
  end)

  it("remove trailing whitespace from description", function()
    local snippet = {
      trigger = "fn",
      description = "desc 	",
      body = { { type = NodeType.TEXT, text = "body" } },
    }
    local actual = converter.convert(snippet)
    local expected = [[
snippet fn desc
	body]]
    assert.are_same(expected, actual)
  end)

  it("replace newline characters with whitespace in description #3", function()
    local snippet = {
      trigger = "fn",
      description = [[
First line
Second line]],
      body = { { type = NodeType.TEXT, text = "body" } },
    }
    local actual = converter.convert(snippet)
    local expected = [[
snippet fn First line Second line
	body]]
    assert.are_same(expected, actual)
  end)

  it("fail to convert regex trigger code", function()
    local snippet = {
      trigger = "fu?n",
      options = "r",
      body = {},
    }
    local ok, actual = pcall(converter.convert, snippet)
    assert.is_false(ok)
    assert.are_same([[conversion of regex trigger is not supported]], actual)
  end)
end)

describe("SnipMate converter (LuaSnip flavor) should", function()
  it("convert snippet priorities", function()
    local snippet = {
      trigger = "fn",
      priority = -100,
      body = {
        {
          type = NodeType.TEXT,
          text = "body",
        },
      },
    }
    local actual = converter.convert(snippet, { flavor = "luasnip" })
    local expected = [[
priority -100
snippet fn
	body]]
    assert.are_same(expected, actual)
  end)

  it("fail to convert Vimscript code", function()
    local snippet = {
      trigger = "fn",
      body = {
        {
          type = NodeType.VIMSCRIPT_CODE,
          code = [[strftime("%H:%M")]],
        },
      },
    }
    local ok, actual = pcall(converter.convert, snippet, { flavor = "luasnip" })
    assert.is_false(ok)
    assert.are_same([[conversion of Vimscript code is not supported]], actual)
  end)
end)

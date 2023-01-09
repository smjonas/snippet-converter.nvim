local parser = require("snippet_converter.core.vscode.body_parser")
local NodeType = require("snippet_converter.core.node_type")

describe("VSCode body parser should", function()
  it("parse tabstop and placeholder", function()
    local input = "local ${1:name} = function($2)"
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    local expected = {
      { type = NodeType.TEXT, text = "local " },
      {
        type = NodeType.PLACEHOLDER,
        int = "1",
        any = { { type = NodeType.TEXT, text = "name" } },
      },
      { type = NodeType.TEXT, text = " = function(" },
      { int = "2", type = NodeType.TABSTOP },
      { type = NodeType.TEXT, text = ")" },
    }
    assert.are_same(expected, actual)
  end)

  it("parse variable with transform", function()
    local input = "${TM_FILENAME/(.*)/${1:/upcase}/}"
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    local expected = {
      {
        var = "TM_FILENAME",
        transform = {
          type = NodeType.TRANSFORM,
          regex = "(.*)",
          regex_kind = NodeType.RegexKind.JAVASCRIPT,
          replacement = {
            { int = "1", format_modifier = "upcase", type = NodeType.FORMAT },
          },
          options = "",
        },
        type = NodeType.VARIABLE,
      },
    }
    assert.are_same(expected, actual)
  end)

  it("parse visual placeholder", function()
    local input = "${TM_SELECTED_TEXT:${1:default}}"
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    local expected = {
      {
        type = NodeType.VISUAL_PLACEHOLDER,
        any = {
          type = NodeType.PLACEHOLDER,
          int = "1",
          any = { { type = NodeType.TEXT, text = "default" } },
        },
      },
    }
    assert.are_same(expected, actual)
  end)

  it("parse format with if text", function()
    local input = [[${1//${2:+if_text}/}]]
    local expected = {
      {
        int = "1",
        transform = {
          regex = "",
          regex_kind = NodeType.RegexKind.JAVASCRIPT,
          options = "",
          replacement = {
            { if_text = "if_text", int = "2", type = NodeType.FORMAT },
          },
          type = NodeType.TRANSFORM,
        },
        type = NodeType.TABSTOP,
      },
    }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("parse format with if and else text", function()
    local input = [[${1//${2:?if_text:else_text}/}]]
    local expected = {
      {
        int = "1",
        transform = {
          regex = "",
          regex_kind = NodeType.RegexKind.JAVASCRIPT,
          options = "",
          replacement = {
            { if_text = "if_text", else_text = "else_text", int = "2", type = NodeType.FORMAT },
          },
          type = NodeType.TRANSFORM,
        },
        type = NodeType.TABSTOP,
      },
    }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("parse format with else texts", function()
    local input = [[${1//${2:else_text 1}${3:-else_text 2}/}]]
    local expected = {
      {
        int = "1",
        transform = {
          regex = "",
          regex_kind = NodeType.RegexKind.JAVASCRIPT,
          options = "",
          replacement = {
            { else_text = "else_text 1", int = "2", type = NodeType.FORMAT },
            { else_text = "else_text 2", int = "3", type = NodeType.FORMAT },
          },
          type = NodeType.TRANSFORM,
        },
        type = NodeType.TABSTOP,
      },
    }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("parse choice node", function()
    local input = "${1|🠂,⇨|}"
    local expected = {
      { int = "1", text = { "🠂", "⇨" }, type = NodeType.CHOICE },
    }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("error out on invalid choice node", function()
    local input = "${0|🠂,⇨|}"
    local expected = "choice node placeholder must not be 0 at '🠂,⇨|}' (input line: '${0|🠂,⇨|}')"
    local ok, actual = parser:parse(input)
    assert.is_false(ok)
    assert.are_same(expected, actual)
  end)

  it("handle escaped chars in choice node", function()
    local input = [[${1|\$,\},\\,\,,\||}]]
    local expected = {
      { int = "1", text = { "$", "}", [[\]], ",", "|" }, type = NodeType.CHOICE },
    }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("handle escaped chars in text node", function()
    local input = [[\$\}\\]]
    -- In contrast to the UltiSnips parser, the input string "\\" is a double backslash
    -- because unescaping of backslashes was already done while reading the JSON file.
    local expected = { { type = NodeType.TEXT, text = [[$}\\]] } }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("handle escaped chars in text node + following tabstop", function()
    local input = [[\{$1\\} $0]]
    -- In contrast to the UltiSnips parser, the input string "\\" is a double backslash
    -- because unescaping of backslashes was already done while reading the JSON file.
    local expected = {
      { type = NodeType.TEXT, text = [[\{]] },
      { type = NodeType.TABSTOP, int = "1" },
      -- a backslash before a } escapes it
      { type = NodeType.TEXT, text = [[\} ]] },
      { type = NodeType.TABSTOP, int = "0" },
    }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("parse unambiguous unescaped chars", function()
    local input = [[${\cup}$]]
    local expected = {
      {
        -- $ does not need to be escaped because it does not mark the beginning of a tabstop
        text = [[${\cup}$]],
        type = NodeType.TEXT,
      },
    }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)

  it("parse incomplete transform", function()
    local input = [[${1/abc/xyz}]]
    local expected = {
      { text = "${1/abc/xyz}", type = NodeType.TEXT },
    }
    local ok, actual = parser:parse(input)
    assert.is_true(ok)
    assert.are_same(expected, actual)
  end)
end)

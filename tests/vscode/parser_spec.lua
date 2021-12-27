local parser = require("snippet_converter.vscode.parser")

describe("VSCode parser", function()
  describe("should parse", function()
    it("multiple snippets", function()
      local data = {
        ["a function"] = {
          prefix = "fn",
          description = "function",
          body = "function ${1:name}($2)\n\t${3:-- code}\nend"
        },
        ["for"] = {
          prefix = "for",
          body = "for ${1:i}=${2:1},${3:10} do\n\t${0:print(i)}\nend",
        }
      }
      local expected = {
        {
          name = "a function",
          trigger = "fn",
          description = "function",
          body = { "function ${1:name}($2)", "\t${3:-- code}", "end" },
        },
        {
          name = "for",
          trigger = "for",
          body = { "for ${1:i}=${2:1},${3:10} do", "\t${0:print(i)}", "end" },
        },
      }
      local actual = parser.parse(data)
      assert.are_same(expected, actual)
    end)
  end)

  describe("should not parse", function()
    it("empty json", function()
      local data = {}
      local actual = parser.parse(data)
      assert.are_same({}, actual)
    end)

    it("when prefix is missing", function()
      local data = {
        ["fn"] = {
          body = "function ${1:name}($2)\n\t${3:-- code}\nend"
        }
      }
      local actual = parser.parse(data)
      assert.are_same({}, actual)
    end)

    it("when body is table", function()
      local data = {
        ["fn"] = {
          prefix = "fn",
          body = { "for ${1:i}=${2:1},${3:10} do", "\t${0:print(i)}", "end" }
        }
      }
      local actual = parser.parse(data)
      assert.are_same({}, actual)
    end)
  end)
end)

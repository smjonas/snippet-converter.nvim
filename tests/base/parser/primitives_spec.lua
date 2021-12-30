local primitives = require("snippet_converter.base.parser.primitives")

local int = primitives.pattern("%d+")
local letters = primitives.pattern("[a-zA-Z]+")

local bind = primitives.bind
local either = primitives.either
local all = primitives.all
local at_least = primitives.at_least

describe("Primitives", function()
  describe("pattern", function()
    it("should parse int and return match, remainder", function()
      local input = "123test"
      local match, remainder, captures = int(input)
      assert.are_same("123", match)
      assert.are_same("test", remainder)
      assert.are_same("123", captures)
    end)

    it("should return nil if pattern does not match", function()
      local input = "-NaN"
      local match, remainder, captures = int(input)
      assert.is_nil(match)
      assert.is_nil(remainder)
      assert.is_nil(captures)
    end)
  end)

  describe("either", function()
    it("should return match, remainder if first parser matched", function()
      local input = "123abc"
      local match, remainder, captures = either { int, letters }(input)
      assert.are_same("123", match)
      assert.are_same("abc", remainder)
      assert.is_nil(captures)
    end)

    it("should return match, remainder if last parser matched", function()
      local input = "abc123"
      local match, remainder, captures = either { letters, int }(input)
      assert.are_same("abc", match)
      assert.are_same("123", remainder)
      assert.is_nil(captures)
    end)

    it("should work with bind and store captured value in match table", function()
      local input = "abc123"
      local match, remainder, captures = either {
        bind("some identifier", letters), int
      }(input)
      assert.are_same("abc", match)
      assert.are_same("123", remainder)
      assert.are_same({ ["some identifier"] = "abc" }, captures)
    end)

    it("should return nil with bound parser when input is not matched", function()
      local input = "!will not be matched!"
      local match, remainder, captures = either {
        bind("some identifier", letters), int
      }(input)
      assert.is_nil(match)
      assert.is_nil(remainder)
      assert.is_nil(captures)
    end)
  end)

  describe("all", function()
    it("should return match, remainder if all parsers matched", function()
      local input = "123abc"
      local match, remainder, captures = all { int, letters }(input)
      assert.are_same("123abc", match)
      assert.are_same("", remainder)
      assert.is_nil(captures)
    end)

    it("should return nil if last parser did not match", function()
      local input = "123 <no letters :/"
      local match, remainder, captures = all { letters, int }(input)
      assert.is_nil(match)
      assert.is_nil(remainder)
      assert.is_nil(captures)
    end)

    it("should work with bind and store captured value in match table", function()
      local input = "abc123 remainder"
      local match, remainder, captures = all {
        bind("letters ID", letters), bind("int ID", int)
      }(input)

      assert.are_same("abc123", match)
      assert.are_same(" remainder", remainder)
      assert.are_same({
        ["letters ID"] = "abc",
        ["int ID"] = "123"
      }, captures)
    end)
  end)

  describe("at_least", function()
    it("should return match, remainder (greedy) if parser matched often enough", function()
      local input = "abababababccc"
      local match, remainder, captures = at_least(3, primitives.pattern("ab"))(input)
      assert.are_same("ababababab", match)
      assert.are_same("ccc", remainder)
      assert.is_nil(captures)
    end)

    it("should return nil if parser did not match often enough", function()
      local input = "aaAA"
      local match, remainder, captures = at_least(3, primitives.pattern("a"))(input)
      assert.is_nil(match)
      assert.is_nil(remainder)
      assert.is_nil(captures)
    end)

    it("should not advance for amount = 0 when not matching", function()
      local input = "123"
      local match, remainder, captures = at_least(0, primitives.pattern("a"))(input)
      assert.are_same("", match)
      assert.are_same("123", remainder)
      assert.is_nil(captures)
    end)

    it("should work with bind and store results in captures table", function()
      local input = "123abc"
      local match, remainder, captures = at_least(2, bind("ints", primitives.pattern("%d")))(input)
      assert.are_same("123", match)
      assert.are_same("abc", remainder)
      assert.are_same(
        {
          ["ints"] = { "1", "2", "3" }
        }, captures
      )
    end)

  end)
end)


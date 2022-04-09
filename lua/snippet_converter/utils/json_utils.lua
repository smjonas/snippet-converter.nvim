--[[

Utility function that turns a Lua table into a nicely formatted JSON string (pretty-printing).

---

pretty_print(data: table, compare: function, escape_special_chars: boolean) -> string

Basic usage:

json_pretty_print.pretty_print({
  key = {
    a_table = {
      A = "v1",
      B = "v2",
    },
    an_array = { "one", 2 },
  },
})

returns the string:

{
  "key": {
    "a_table": {
      "A": "v1",
      "B": "v2"
    },
    "an_array": [
      "one",
      2
    ]
  }
}

By default, keys in tables are sorted alhabetically. To change this, pass a different
comparison function to stringify. This function should take as arguments the two keys
to compare and return a boolean that determines whether the first argument should be
output before the second or not.

If you want to escape any special characters, set escape_special_chars to true.
Otherwise each table value will be output as is.

--]]

local tbl = require("snippet_converter.utils.table")

local M = {}

function M:escape_chars(str)
  -- Escape escape sequences (see http://www.lua.org/manual/5.1/manual.html#2.1).
  -- Also escape '\', '}' and '$' characters.
  return str:gsub("[\\}%$\"'\a\b\f\n\r\t\v]", {
    ["\\"] = "\\\\",
    ["}"] = "\\}",
    ["$"] = "\\$",
    ['"'] = '\\"',
    ["\a"] = "\\a",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
    ["\v"] = "\\v",
  })
end

function M:format_string(value)
  local result = self.escape_special_chars and self:escape_chars(value) or value
  self:emit(([["%s"]]):format(result), true)
end

function M:format_table(value, add_indent)
  local tbl_count = vim.tbl_count(value)
  self:emit("{\n", add_indent)
  self.indent = self.indent + 2
  local prev_indent = self.indent
  local i = 1
  for k, v in tbl.pairs_by_keys(value, self.compare) do
    self:emit(('"%s": '):format(k), true)
    if type(v) == "string" then
      -- Reset indent temporarily
      self.indent = 0
    end
    self:format_value(v)
    self.indent = prev_indent
    if i == tbl_count then
      self:emit("\n")
    else
      self:emit(",\n")
    end
    i = i + 1
  end
  self.indent = self.indent - 2
  self:emit("}", true)
end

function M:format_array(value)
  local array_count = #value
  self:emit("[\n")
  self.indent = self.indent + 2
  for i, item in ipairs(value) do
    -- Also indent the following items
    self:format_value(item, true)
    if i == array_count then
      self:emit("\n")
    else
      self:emit(",\n")
    end
  end
  self.indent = self.indent - 2
  self:emit("]", true)
end

function M:emit(value, add_indent)
  if add_indent then
    self.out[#self.out + 1] = (" "):rep(self.indent)
  end
  self.out[#self.out + 1] = value
end

function M:format_value(value, add_indent)
  if value == nil then
    self:emit("null")
  end
  local _type = type(value)
  if _type == "string" then
    self:format_string(value)
  elseif _type == "number" then
    self:emit(tostring(value), add_indent)
  elseif _type == "table" then
    local count = vim.tbl_count(value)
    if count == 0 then
      self:emit("{}")
    elseif #value > 0 then
      self:format_array(value)
    else
      self:format_table(value, add_indent)
    end
  end
end

function M:pretty_print(data, compare, escape_special_chars)
  self.compare = compare
  self.escape_special_chars = escape_special_chars
  self.indent = 0
  self.out = {}
  self:format_value(data, false)
  return table.concat(self.out)
end

return M

local tbl = require("snippet_converter.utils.table")

local M = {}

function M:escape_chars(str)
  -- Escape escape sequences (see http://www.lua.org/manual/5.1/manual.html#2.1).
  return str:gsub('[\\"\a\b\f\n\r\t\v]', {
    ["\\"] = "\\\\",
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
  -- This might be incorrect for more than two levels because the
  -- table to iterate over is always the same
  for k, v in tbl.pairs_by_keys(value, self.compare[self.indent / 2] or self.default_compare) do
    self:emit(('"%s": '):format(self.escape_special_chars and self:escape_chars(k) or k), true)
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
  elseif _type == "number"  then
    self:emit(tostring(value), add_indent)
  elseif _type == "boolean" then
    self:emit(value == true and "true" or "false", add_indent)
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

--[[

Utility function that turns a Lua table into a nicely formatted JSON string (pretty-printing).

---

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
--]]
--- Utility function that turns a Lua table into a nicely formatted JSON string (pretty-printing).
---@param data table the table to pretty-print
---@param keys_orders table a table where the value for each key (the indentation level) is an array of keys that determines their order in the output
---@param escape_special_chars boolean
---@return string the pretty-printed string
function M:pretty_print(data, keys_orders, escape_special_chars)
  self.compare = {}
  if keys_orders then
    for indentation_level, keys_order in pairs(keys_orders) do
      local order = {}
      for i, key in ipairs(keys_order) do
        order[key] = i
      end
      local max_pos = #keys_order + 1
      self.compare[indentation_level] = function(a, b)
        return (order[a] or max_pos) - (order[b] or max_pos) < 0
      end
    end
  end
  self.default_compare = function(a, b)
    return a:lower() < b:lower()
  end
  self.escape_special_chars = escape_special_chars
  self.indent = 0
  self.out = {}
  self:format_value(data, false)
  return table.concat(self.out)
end

return M

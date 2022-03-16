local M = {}

M.new = function()
  return setmetatable({
    compare = function(a, b)
      return a:lower() < b:lower()
    end,
  }, { __index = M })
end

function M:escape_chars(str)
  -- Escape backslashes (I couldn't get this to work with gsub / regexes)
  local chars = {}
  for i = 1, #str do
    local cur_char = str:sub(i, i)
    if cur_char == "\\" then
      chars[#chars + 1] = "\\"
    end
    chars[#chars + 1] = cur_char
  end

  local item = table.concat(chars)
  -- Surround with quotes and escape whitespace + quote characters
  return ('"%s"'):format(item:gsub('[\t\r\a\b"]', {
    ["\t"] = "\\t",
    ["\r"] = "\\r",
    ["\a"] = "\\a",
    ["\b"] = "\\b",
    ['"'] = '\\"',
  }))
end

function M:format_string(value)
  local result = self.escape_special_chars and self:escape_chars(value) or value
  self:emit(([["%s"]]):format(result), true)
end

local pairs_by_keys = function(tbl, compare)
  local keys = {}
  for key, _ in pairs(tbl) do
    table.insert(keys, key)
  end
  table.sort(keys, compare)
  local i = 0
  -- Return an iterator function
  return function()
    i = i + 1
    return keys[i] and keys[i], tbl[keys[i]] or nil
  end
end

function M:format_table(value, add_indent)
  local tbl_count = vim.tbl_count(value)
  self:emit("{\n", add_indent)
  self.indent = self.indent + 2
  local prev_indent = self.indent
  local i = 1
  for k, v in pairs_by_keys(value, self.compare) do
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
  local _type = type(value)
  if _type == "string" then
    self:format_string(value)
  elseif _type == "table" then
    local count = vim.tbl_count(value)
    if count == 0 then
      self:emit("[]")
    elseif #value > 0 then
      self:format_array(value)
    else
      self:format_table(value, add_indent)
    end
  end
end

function M:stringify(data, compare, escape_special_chars)
  self.compare = compare or self.compare
  self.escape_special_chars = escape_special_chars
  self.indent = 0
  self.out = {}
  self:format_value(data)
  return table.concat(self.out)
end

return M

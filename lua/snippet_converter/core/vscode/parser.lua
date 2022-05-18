local body_parser = require("snippet_converter.core.vscode.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.get_lines = function(path)
  return io.read_json(path)
end

---@protected
---@param snippet_name string
---@param snippet_info table
---@param errors_ptr table
---@return boolean ok
M.verify_snippet_format = function(snippet_name, snippet_info, errors_ptr)
  if type(snippet_info) ~= "table" then
    errors_ptr[#errors_ptr + 1] = "snippet must be a table, got " .. type(snippet_name)
    return false
  end
  local assertions = {
    {
      predicate = type(snippet_info) == "table",
      msg = function()
        return "snippet must be a table, got " .. type(snippet_name)
      end,
    },
    {
      predicate = type(snippet_name) == "string",
      msg = function()
        return "snippet name must be a string, got " .. type(snippet_name)
      end,
    },
    {
      predicate = type(snippet_info.prefix) == "string"
        or type(snippet_info.prefix) == "table" and #snippet_info.prefix > 0,
      msg = function()
        return "prefix must be string or non-empty table, got " .. type(snippet_info.prefix)
      end,
    },
    {
      predicate = snippet_info.description == nil or type(snippet_info.description) == "string",
      msg = function()
        return "description must be string or nil, got " .. type(snippet_info.description)
      end,
    },
    {
      predicate = snippet_info.scope == nil or type(snippet_info.scope) == "string",
      msg = function()
        return "scope must be string or nil, got " .. type(snippet_info.scope)
      end,
    },
    {
      predicate = type(snippet_info.body) == "table" or type(snippet_info.body) == "string",
      msg = function()
        return "body must be list or string, got " .. type(snippet_info.body)
      end,
    },
  }
  return err.assert_all(assertions, errors_ptr)
end

---@protected
---@return table
M.create_snippet = function(snippet_name, trigger, snippet_info, parser, parser_errors_ptr)
  local body = type(snippet_info.body) == "string" and { snippet_info.body } or snippet_info.body
  parser = parser or body_parser
  local ok, result = parser:parse(table.concat(body, "\n"))
  if not ok then
    parser_errors_ptr[#parser_errors_ptr + 1] = result
    return nil
  end
  return {
    name = snippet_name,
    trigger = trigger,
    scope = snippet_info.scope and vim.split(snippet_info.scope, ","),
    description = snippet_info.description,
    body = result,
  }
end

M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr, args)
  args = args or {}
  -- This is a bit ugly but changing all parsers to a class is a lot of effort
  args.self = args.self or M
  local snippet_data = args.lines or M.get_lines(path)
  if vim.tbl_isempty(snippet_data) then
    return #parsed_snippets_ptr
  end
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1
  for snippet_name, snippet_info in pairs(snippet_data) do
    if args.self.verify_snippet_format(snippet_name, snippet_info, parser_errors_ptr) then
      -- The snippet can have multiple prefixes
      local triggers = type(snippet_info.prefix) == "table" and snippet_info.prefix or { snippet_info.prefix }
      for _, trigger in ipairs(triggers) do
        local snippet = args.self.create_snippet(
          snippet_name,
          trigger,
          snippet_info,
          args.parser,
          parser_errors_ptr
        )
        if snippet then
          snippet.path = path
          parsed_snippets_ptr[pos] = snippet
          pos = pos + 1
        end
      end
    end
  end
  return (pos - 1) - prev_count
end

return M

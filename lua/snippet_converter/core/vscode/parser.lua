local body_parser = require("snippet_converter.core.vscode.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.filter_paths = function(paths)
  return vim.tbl_filter(function(path)
    return not path:find("package%.json$")
  end, paths)
end

M.get_lines = function(path)
  return io.read_json(path)
end

---@param snippet_name string
---@param snippet_info table
---@param errors_ptr table
---@return boolean ok
M.verify_snippet_format = function(snippet_name, snippet_info, errors_ptr, opts)
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
  local ok = err.assert_all(assertions, errors_ptr)
  if not ok or opts.flavor ~= "luasnip" then
    return ok
  end

  -- flavor == "luasnip"
  -- Somehow the type of 'nil' can be 'table' so also add a nil-check...
  local got_luasnips_key = snippet_info.luasnip ~= nil and type(snippet_info.luasnip) == "table"
  local autotrigger = got_luasnips_key and snippet_info.luasnip.autotrigger
  local priority = got_luasnips_key and snippet_info.luasnip.priority

  assertions = {
    {
      predicate = (snippet_info.luasnip == nil) or got_luasnips_key,
      msg = function()
        return "luasnip must be a table, got " .. type(snippet_info.luasnip)
      end,
    },
    {
      predicate = not got_luasnips_key or autotrigger == nil or type(autotrigger) == "boolean",
      msg = function()
        return "luasnip.autotrigger must be a boolean, got " .. type(snippet_name)
      end,
    },
    {
      predicate = not got_luasnips_key or priority == nil or type(priority) == "number",
      msg = function()
        return "luasnip.priority must be a number, got " .. type(snippet_name)
      end,
    },
  }
  return err.assert_all(assertions, errors_ptr)
end

---@return table|nil
M.create_snippet = function(snippet_name, trigger, snippet_info, parser, parser_errors_ptr, opts)
  local body = type(snippet_info.body) == "string" and { snippet_info.body } or snippet_info.body
  parser = parser or body_parser
  local ok, result = parser:parse(table.concat(body, "\n"))
  if not ok then
    parser_errors_ptr[#parser_errors_ptr + 1] = result
    return nil
  end
  local snippet = {
    name = snippet_name,
    trigger = trigger,
    scope = snippet_info.scope and vim.split(snippet_info.scope, ","),
    description = snippet_info.description,
    body = result,
  }
  if opts.flavor == "luasnip" then
    if snippet_info.luasnip then
      snippet.priority = snippet_info.luasnip.priority
      if snippet_info.luasnip.autotrigger == true then
        snippet.autotrigger = true
      end
    end
  end
  return snippet
end

---@param path string the path to the snippet file used by get_lines
---@param parsed_snippets_ptr table contains all previously parsed snippets, any new snippets will be added to the end of it
---@param parser_errors_ptr table contains all previously encountered errors, any new errors that occur during parsing will be added to the end of it
---@param opts? table opts.flavor can be "luasnip" or nil
---@return number the updated number of snippets that have been parsed
M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr, opts)
  opts = opts or {}
  -- This is a bit ugly but changing all parsers to a class is a lot of effort
  opts.self = opts.self or M

  local snippet_data = opts.lines or M.get_lines(path)
  if vim.tbl_isempty(snippet_data) then
    return #parsed_snippets_ptr
  end

  local prev_count = #parsed_snippets_ptr
  local num_snippets = prev_count + 1
  for snippet_name, snippet_info in pairs(snippet_data) do
    if opts.self.verify_snippet_format(snippet_name, snippet_info, parser_errors_ptr, opts) then
      -- The snippet can have multiple prefixes
      local triggers = type(snippet_info.prefix) == "table" and snippet_info.prefix or { snippet_info.prefix }
      for _, trigger in ipairs(triggers) do
        local snippet =
          opts.self.create_snippet(snippet_name, trigger, snippet_info, opts.parser, parser_errors_ptr, opts)
        if snippet then
          snippet.path = path
          parsed_snippets_ptr[num_snippets] = snippet
          num_snippets = num_snippets + 1
        end
      end
    end
  end
  return (num_snippets - 1) - prev_count
end

return M

local body_parser = require("snippet_converter.core.vscode.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.get_lines = function(path)
  return io.read_json(path)
end

local verify_snippet_format = function(snippet_name, snippet_info, errors_ptr)
  local assertions = {
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

local create_snippet = function(snippet_name, trigger, snippet_info, parser, parser_errors_ptr)
  local body = type(snippet_info.body) == "string" and { snippet_info.body } or snippet_info.body
  parser = parser or body_parser
  local ok, result = pcall(parser.parse, parser, table.concat(body, "\n"))
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

M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr, _, parser)
  local snippet_data = M.get_lines(path)
  if vim.tbl_isempty(snippet_data) then
    return #parsed_snippets_ptr
  end
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1
  for snippet_name, snippet_info in pairs(snippet_data) do
    if verify_snippet_format(snippet_name, snippet_info, parser_errors_ptr) then
      -- The snippet has multiple prefixes.
      if type(snippet_info.prefix) == "table" then
        for _, trigger in ipairs(snippet_info.prefix) do
          local snippet = create_snippet(
            snippet_name,
            trigger,
            snippet_info,
            parser,
            parser_errors_ptr
          )
          if snippet then
            snippet.path = path
            parsed_snippets_ptr[pos] = snippet
            pos = pos + 1
          end
        end
      else
        local snippet = create_snippet(
          snippet_name,
          snippet_info.prefix,
          snippet_info,
          parser,
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

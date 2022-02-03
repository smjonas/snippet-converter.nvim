local body_parser = require("snippet_converter.core.vscode.body_parser")
local utils = require("snippet_converter.utils.file_utils")
local err = require("snippet_converter.utils.error")

local parser = {}

parser.get_lines = function(file)
  return utils.json_decode(file)
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
      predicate = type(snippet_info.body) == "table",
      msg = function()
        return "body must be list, got " .. type(snippet_info.body)
      end,
    },
  }
  return err.assert_all(assertions, errors_ptr)
end

parser.parse = function(snippet_data, parsed_snippets_ptr, parser_errors_ptr)
  if vim.tbl_isempty(snippet_data) then
    return 0
  end
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1
  for snippet_name, snippet_info in pairs(snippet_data) do
    if verify_snippet_format(snippet_name, snippet_info, parser_errors_ptr) then
      parsed_snippets_ptr[pos] = {
        name = snippet_name,
        trigger = snippet_info.prefix,
        description = snippet_info.description,
        body = body_parser.parse(table.concat(snippet_info.body, "\n")),
      }
      pos = pos + 1
    end
  end
  return (pos - 1) - prev_count
end

return parser

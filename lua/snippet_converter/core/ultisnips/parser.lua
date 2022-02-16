local header_parser = require("snippet_converter.core.ultisnips.header_parser")
local body_parser = require("snippet_converter.core.ultisnips.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.get_lines = function(path)
  return io.read_file(path)
end

-- TODO: docs for return values and params
-- TODO: change first parameter to take lines instead of path
M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr)
  local lines = M.get_lines(path)
  local cur_snippet
  local found_snippet_header = false
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1

  for line_nr, line in ipairs(lines) do
    if not found_snippet_header then
      local header = M.parse_header(line)
      if header then
        cur_snippet = header
        cur_snippet.path = path
        cur_snippet.line_nr = line_nr
        cur_snippet.body = {}
        found_snippet_header = true
      end
    -- TODO: change
    elseif vim.startswith(line, "endsnippet") then
      local ok, result = pcall(body_parser.parse, table.concat(cur_snippet.body, "\n"))
      if ok then
        cur_snippet.body = result
        parsed_snippets_ptr[pos] = cur_snippet
        pos = pos + 1
      else
        local start_line_nr = line_nr - #cur_snippet.body
        parser_errors_ptr[#parser_errors_ptr + 1] = err.new_parser_error(path, start_line_nr, result)
      end
      found_snippet_header = false
    else
      table.insert(cur_snippet.body, line)
    end
  end
  -- Return the number of snippets that have been parsed
  return (pos - 1) - prev_count
end

M.parse_header = function(line)
  local stripped_header = line:match("^%s*snippet%s+(.-)%s*$")
  if stripped_header ~= nil then
    local header = header_parser.parse(stripped_header)
    return not vim.tbl_isempty(header) and header
  end
end

return M

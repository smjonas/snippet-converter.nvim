local header_parser = require("snippet_converter.ultisnips.header_parser")
local body_parser = require("snippet_converter.ultisnips.body_parser")
local utils = require("snippet_converter.utils")
local err = require("snippet_converter.error")

local parser = {}

function parser.get_lines(file)
  return utils.read_file(file)
end

-- TODO: docs for return values and params
function parser.parse(parsed_snippets_ptr, lines, parser_errors_ptr)
  local cur_snippet
  local found_snippet_header = false
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1

  for i, line in ipairs(lines) do
    if not found_snippet_header then
      local header = parser.parse_header(line)
      if header then
        cur_snippet = header
        cur_snippet.body = {}
        found_snippet_header = true
      end
    elseif vim.startswith(line, "endsnippet") then
      local ok, result = pcall(body_parser.parse, table.concat(cur_snippet.body, "\n"))
      if ok then
        cur_snippet.body = result
        parsed_snippets_ptr[pos] = cur_snippet
        pos = pos + 1
      else
        parser_errors_ptr[#parser_errors_ptr + 1] = err.create_parser_error(i, result)
      end
      found_snippet_header = false
    else
      table.insert(cur_snippet.body, line)
    end
  end
  -- Return the number of snippets that have been parsed
  return (pos - 1) - prev_count
end

function parser.parse_header(line)
  local stripped_header = line:match("^%s*snippet%s+(.-)%s*$")
  if stripped_header ~= nil then
    local header = header_parser.parse(stripped_header)
    return not vim.tbl_isempty(header) and header
  end
end

return parser

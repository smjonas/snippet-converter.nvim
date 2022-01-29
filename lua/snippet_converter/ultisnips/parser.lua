local header_parser = require("snippet_converter.ultisnips.header_parser")
local body_parser = require("snippet_converter.ultisnips.body_parser")
local utils = require("snippet_converter.utils")

local parser = {}

function parser.get_lines(file)
  return utils.read_file(file)
end

function parser.parse(parsed_snippets_ptr, lines)
  local cur_snippet
  local found_snippet_header = false
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1

  for _, line in ipairs(lines) do
    if not found_snippet_header then
      local header = parser.parse_header(line)
      if header then
        cur_snippet = header
        cur_snippet.body = {}
        found_snippet_header = true
      end
    elseif vim.startswith(line, "endsnippet") then
      cur_snippet.body = body_parser.parse(table.concat(cur_snippet.body, "\n"))
      parsed_snippets_ptr[pos] = cur_snippet
      found_snippet_header = false
      pos = pos + 1
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

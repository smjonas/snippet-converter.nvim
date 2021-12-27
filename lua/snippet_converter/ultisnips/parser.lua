local header_parser = require("snippet_converter.ultisnips.header_parser")
local utils = require("snippet_converter.utils")

local parser = {}

function parser.get_lines(file)
  return utils.read_file(file)
end

function parser.parse(lines)
  local parsed_snippets = {}
  local cur_snippet
  local found_snippet_header = false

  for _, line in ipairs(lines) do
    if not found_snippet_header then
      local header = parser.get_header(line)
      if header then
        cur_snippet = header
        cur_snippet.body = {}
        found_snippet_header = true
      end
    elseif vim.startswith(line, "endsnippet") then
      parsed_snippets[#parsed_snippets + 1] = cur_snippet
      found_snippet_header = false
    else
      table.insert(cur_snippet.body, line)
    end
  end
  return parsed_snippets
end

function parser.get_header(line)
  local stripped_header = line:match("^%s*snippet%s+(.-)%s*$")
  if stripped_header ~= nil then
    local header = header_parser.parse(stripped_header)
    return not vim.tbl_isempty(header) and header
  end
end

return parser

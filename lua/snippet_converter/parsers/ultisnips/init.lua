local base_parser = require("snippet_converter.parsers.base")
local header_parser = require("snippet_converter.parsers.ultisnips.header_parser")
local utils = require("snippet_converter.utils")

local parser = base_parser:new()

function parser:parse(file)
  local parsed_snippets = {}
  local cur_snippet
  local lines = utils.read_file(file)
  local found_snippet_header = false

  for _, line in ipairs(lines) do
    if not found_snippet_header then
      local header = self:get_header(line)
      if header then
        cur_snippet = header
        cur_snippet.body = {}
        found_snippet_header = true
      end
    elseif found_snippet_header and vim.startswith(line, "endsnippet") then
      parsed_snippets[#parsed_snippets + 1] = cur_snippet
      found_snippet_header = false
    else
      table.insert(cur_snippet.body, line)
    end
  end
  return parsed_snippets
end

function parser:get_header(line)
  local stripped_header = line:match("^%s*snippet%s+(.-)%s*$")
  if stripped_header ~= nil then
    local header = header_parser.parse(stripped_header)
    return not vim.tbl_isempty(header) and header
  end
end

return parser

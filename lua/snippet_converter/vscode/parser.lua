local utils = require("snippet_converter.utils")

local parser = {}

function parser.get_lines(file)
  return utils.json_decode(utils.read_file(file))
end

function parser.parse(lines)
  local parsed_snippets = {}
  local cur_snippet

  for _, line in ipairs(lines) do
    local header = parser.get_header(line)
    -- Found possible snippet header
    if header then
      if cur_snippet ~= nil then
        parsed_snippets[#parsed_snippets + 1] = cur_snippet
      end
      cur_snippet = header
      cur_snippet.body = {}
    elseif cur_snippet ~= nil then
      if line:match("^\t") then
        table.insert(cur_snippet.body, line:sub(2))
      end
    end
  end
  -- Store last snippet
  parsed_snippets[#parsed_snippets + 1] = cur_snippet
  return parsed_snippets
end

function parser.get_header(line)
  local stripped_header = line:match("^%s*snippet!?!?%s(.*)")
  if stripped_header ~= nil then
    local words = vim.split(stripped_header, "%s", { trim_empty = true })
    local header = {
      trigger = table.remove(words, 1),
    }
    if #words >= 1 then
      header.description = vim.fn.join(words, " ")
    end
    return header
  end
end

return parser

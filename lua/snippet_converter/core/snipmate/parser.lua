local io = require("snippet_converter.utils.io")

local parser = {}

parser.get_lines = function(file)
  return io.read_file(file)
end

parser.parse = function(path, parsed_snippets_ptr, parser_errors_ptr)
  local lines = parser.get_lines(path)
  local cur_snippet
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1

  for _, line in ipairs(lines) do
    local header = parser.get_header(line)
    -- Found possible snippet header
    if header then
      if cur_snippet ~= nil then
        parsed_snippets_ptr[pos] = cur_snippet
        pos = pos + 1
      end
      cur_snippet = header
      cur_snippet.body = {}
    elseif cur_snippet ~= nil then
      if line:match("^\t") then
        table.insert(cur_snippet.body, line:sub(2))
      end
    end
  end
  -- Return the number of snippets that have been parsed
  return (pos - 1) - prev_count
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

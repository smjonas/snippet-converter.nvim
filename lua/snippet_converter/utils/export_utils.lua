local M = {}

local io = require("snippet_converter.utils.io")

M.snippet_strings_to_lines = function(snippets_ptr, sep_chars, header, footer)
  local len = #snippets_ptr
  local total_len = 0

  local snippet_lines = {}
  local cur_snippet_lines
  for i = 1, len do
    if i ~= len then
      -- Append append_chars to every snippet except the last one
      snippets_ptr[i] = string.format("%s" .. sep_chars, snippets_ptr[i])
    end
    -- Replace "\n" with new line
    cur_snippet_lines = vim.split(snippets_ptr[i], "\n", true)
    local cur_len = #cur_snippet_lines
    for j = 1, cur_len do
      snippet_lines[j + total_len] = cur_snippet_lines[j]
    end
    total_len = total_len + cur_len
  end

  if header ~= nil then
    table.insert(snippet_lines, 1, header)
    total_len = total_len + 1
  end

  if footer ~= nil then
    snippet_lines[total_len + 1] = footer
  end
  return snippet_lines
end

M.get_output_path = function(output_path, filetype, extension)
  if not io.is_file(output_path) then
    print(output_path, "is file")
    output_path = ("%s/%s.%s"):format(output_path, filetype, extension)
  end
  return output_path
end

return M

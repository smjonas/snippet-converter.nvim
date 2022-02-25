local M = {}

local io = require("snippet_converter.utils.io")

M.snippet_strings_to_lines = function(snippets_ptr, sep_chars, headers, footer, snippet_lines_ptr)
  local len = #snippets_ptr
  local total_len = 0

  local snippet_lines = snippet_lines_ptr or {}
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

  if headers ~= nil then
    for i, header in ipairs(headers) do
      table.insert(snippet_lines, i, header)
    end
    total_len = total_len + 1
  end

  if footer ~= nil then
    snippet_lines[total_len + 1] = footer
  end
  return snippet_lines
end

-- If the output_path is already a valid file name, use that as the path,
-- otherwise create a file in the output_path directory with the correct file extension.
M.get_output_file_path = function(output_path, filetype, extension)
  if not output_path:match((".%s$"):format(extension)) then
    output_path = ("%s/%s.%s"):format(output_path, filetype, extension)
  end
  return output_path
end

return M

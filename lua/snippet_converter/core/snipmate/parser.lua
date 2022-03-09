local body_parser = require("snippet_converter.core.snipmate.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.get_lines = function(file)
  return io.read_file(file)
end

-- TODO: reuse this function for UltiSnips + SnipMate
local store_snippet =
  function(cur_snippet, line_nr, path, pos, parsed_snippets_ptr, parser_errors_ptr)
    local ok, result = pcall(body_parser.parse, table.concat(cur_snippet.body, "\n"))
    if ok then
      cur_snippet.body = result
      parsed_snippets_ptr[pos] = cur_snippet
      return true
    else
      local start_line_nr = line_nr - #cur_snippet.body
      parser_errors_ptr[#parser_errors_ptr + 1] = err.new_parser_error(path, start_line_nr, result)
    end
  end

M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr)
  local lines = M.get_lines(path)
  local cur_snippet
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1

  -- TODO: handle `Filename()` inside vimscript code (cannot be converted because the
  -- function is non-standard)
  -- TODO: preserve comments
  for line_nr, line in ipairs(lines) do
    local header = M.get_header(line)
    if header then
      if cur_snippet ~= nil then
        if
          store_snippet(cur_snippet, line_nr, path, pos, parsed_snippets_ptr, parser_errors_ptr)
        then
          pos = pos + 1
        end
      end
      cur_snippet = header
      cur_snippet.path = path
      cur_snippet.line_nr = line_nr
      cur_snippet.body = {}
    elseif cur_snippet ~= nil then
      if line:match("^\t") then
        table.insert(cur_snippet.body, line:sub(2))
      end
    end
  end

  -- The end of the file also marks the end of the last snippet
  if cur_snippet ~= nil then
    if store_snippet(cur_snippet, #lines, path, pos, parsed_snippets_ptr, parser_errors_ptr) then
      pos = pos + 1
    end
  end

  -- Return the new total number of snippets that were parsed
  return (pos - 1) - prev_count
end

function M.get_header(line)
  local stripped_header = line:match("^%s*snippet!?!?%s(.*)")
  if stripped_header ~= nil then
    local words = vim.split(stripped_header, "%s", { trim_empty = true })
    local header = {
      trigger = table.remove(words, 1),
    }
    if #words >= 1 then
      header.description = table.concat(words)
    end
    return header
  end
end

return M

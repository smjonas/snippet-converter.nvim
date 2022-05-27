local body_parser = require("snippet_converter.core.snipmate.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.get_lines = function(file)
  return io.read_file(file)
end

M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr, _, lines_)
  local lines = lines_ or M.get_lines(path)
  local cur_snippet
  local cur_priority
  local prev_count = #parsed_snippets_ptr
  local pos = prev_count + 1

  -- TODO: handle `Filename()` inside vimscript code (cannot be converted because the
  -- function is non-standard)
  -- TODO: preserve comments
  for line_nr, line in ipairs(lines) do
    local header = M.get_header(line)
    if header then
      if cur_snippet ~= nil then
        cur_snippet.body = body_parser.parse(table.concat(cur_snippet.body, "\n"))
        parsed_snippets_ptr[pos] = cur_snippet
        pos = pos + 1
      end
      cur_snippet = header
      cur_snippet.path = path
      cur_snippet.line_nr = line_nr
      cur_snippet.body = {}
      if cur_priority then
        cur_snippet.priority = cur_priority
        cur_priority = nil
      end
    else
      if cur_snippet and line:match("^\t") then
        table.insert(cur_snippet.body, line:sub(2))
      elseif cur_snippet and line:match("^%s*$") then
        -- Whitespace-only line
        table.insert(cur_snippet.body, line)
      else
        -- Priorities are not an official SnipMate feature.
        -- However, LuaSnip extended the syntax so we will support it too.
        local priority = line:match("^priority (%-?%d+)")
        if priority then
          cur_priority = tonumber(priority)
        elseif line:match("^priority") then
          parser_errors_ptr[#parser_errors_ptr + 1] = err.new_parser_error(
            path,
            line_nr,
            ([[invalid priority "%s"]]):format(line)
          )
        end
      end
    end
  end

  -- The end of the file also marks the end of the last snippet
  if cur_snippet ~= nil then
    cur_snippet.body = body_parser.parse(table.concat(cur_snippet.body, "\n"))
    parsed_snippets_ptr[pos] = cur_snippet
    pos = pos + 1
  end

  -- Return the new total number of snippets that were parsed
  return (pos - 1) - prev_count
end

function M.get_header(line)
  local trigger, description = line:match("^snippet!?!?%s+(%S+)%s*(.*)")
  if trigger then
    return {
      trigger = trigger,
      description = description ~= "" and description or nil,
    }
  end
end

return M

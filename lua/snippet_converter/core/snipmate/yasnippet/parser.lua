local body_parser = require("snippet_converter.core.snipmate.yasnippet.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.get_lines = function(file)
  return io.read_file(file)
end

---@return number the updated number of snippets that have been parsed
M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr, _, lines_)
  local prev_count = #parsed_snippets_ptr
  local lines = lines_ or M.get_lines(path)
  local meta_data = {}
  -- Assumes only one snippet per file
  local snippet

  for line_nr, line in ipairs(lines) do
    local property, value = line:match("# (%a+): (.+)")
    if property and value then
      meta_data[property] = value
    end

    -- This marks the beginning of the snippet body
    if line:match("# %-%-") then
      if meta_data["type"] == "command" then
        table.insert(
          parser_errors_ptr,
          err.new_parser_error(path, line_nr + 1, [[unsupported type "command"]])
        )
        return prev_count
      else
        snippet = {
          -- Use last component of the filename as trigger if key is not present
          trigger = meta_data["key"] or vim.fn.fnamemodify(path, ":t"),
          description = meta_data["name"],
          path = path,
          -- The snippet starts at the next line
          line_nr = line_nr + 1,
          body = {},
        }
      end
    elseif snippet then
      table.insert(snippet.body, line)
    end
  end

  if snippet ~= nil then
    snippet.body = body_parser.parse(table.concat(snippet.body, "\n"))
    table.insert(parsed_snippets_ptr, snippet)
    -- One additional snippet was parsed
    return prev_count + 1
  end
  return prev_count
end

return M

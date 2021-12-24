local base_parser = require("snippet_converter.parsers.base")
local utils = require("snippet_converter.utils")

local parser = base_parser:new()

function parser:parse(file)
  local parsed_snippets = {}
  local cur_snippet
  local lines = utils.read_file(file)

  for _, line in ipairs(lines) do
    local header = self:get_header(line)
    -- Found possible snippet header
    if header then
      if cur_snippet ~= nil then
        parsed_snippets[#parsed_snippets + 1] = cur_snippet
      end
      cur_snippet = header
      cur_snippet.body = {}
    elseif cur_snippet ~= nil then
      if line:match("^\t") then
        line = line:sub(2)
      end
      -- TODO: remove potential trailing \n
      table.insert(cur_snippet.body, line)
    end
  end
  return parsed_snippets
end

function parser:get_header(line)
  local trigger, description = line:match("^%s*snippet!?!?%s+(.-)%s*(.*)$")
  if trigger ~= nil then
    return {
      trigger = trigger,
      description = description,
    }
  end
end

return parser

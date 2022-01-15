local body_parser = require("snippet_converter.vscode.body_parser")
local utils = require("snippet_converter.utils")

local parser = {}

function parser.get_lines(file)
  return utils.json_decode(file)
end

function parser.parse(snippet_data)
  local parsed_snippets = {}
  for snippet_name, snippet_info in pairs(snippet_data) do
    local trigger, body = snippet_info.prefix, snippet_info.body
    if type(trigger) == "string" and type(body) == "string" then
      local description
      if type(snippet_info.description) == "string" then
        description = snippet_info.description
      end
      parsed_snippets[#parsed_snippets + 1] = {
        name = snippet_name,
        trigger = trigger,
        description = description,
        body = vim.split(body_parser.parse(body), "\n"),
      }
    end
  end
  return parsed_snippets
end

return parser

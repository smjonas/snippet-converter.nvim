local base_parser = {}

local utils = require("snippet_converter.utils")

base_parser.new = function()
  local self = setmetatable({}, { __index = base_parser })
  return self
end

function base_parser:get_header(line)
  error("header: Parser must implement this function.")
end

return base_parser

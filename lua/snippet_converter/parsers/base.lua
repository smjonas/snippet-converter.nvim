local base_parser = {}

local utils = require("snippet_converter.utils")

base_parser.new = function()
  local self = setmetatable({}, { __index = base_parser })
  return self
end

function base_parser:get_header(line)
  error("header: Parser must implement this function.")
end

-- Parsed snippet must be a table with the following keys:
-- trigger (required)
-- description (optional)
-- body (required) TODO: make sure body can never be {}

return base_parser

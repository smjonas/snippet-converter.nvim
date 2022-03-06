local vscode_parser = require("snippet_converter.core.vscode.parser")
local body_parser = require("snippet_converter.core.vscode.vsnip.body_parser")

local M = setmetatable({}, { __index = vscode_parser })

M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr)
  return vscode_parser.parse(path, parsed_snippets_ptr, parser_errors_ptr, body_parser)
end

return M

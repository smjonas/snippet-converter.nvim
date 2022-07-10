local parser = require("snippet_converter.core.vscode.parser")

parser.parse = function(path, parsed_snippets_ptr, _, _)
  -- Put the path into the list of parsed snippets to check later what the parse
  -- function was called with
  parsed_snippets_ptr[#parsed_snippets_ptr + 1] = path
  return 1
end

return parser

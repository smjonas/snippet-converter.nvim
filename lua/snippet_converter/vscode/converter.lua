local M = {}

local NodeType = require("snippet_converter.base.node_type")
local base_converter = require("snippet_converter.base.converter")
local utils = require("snippet_converter.utils")
local export_utils = require("snippet_converter.base.export_utils")

M.node_handler = setmetatable({}, {
  __index = base_converter.default_node_handler(M.node_handler),
})

M.convert = function(snippet)
  local body = base_converter.convert_ast(snippet.body, base_converter.default_node_handler(nil))
  body = utils.json_encode(vim.fn.split(body, "\n", true))

  local description_string
  if snippet.description then
    description_string = (',\n    "description": "%s"'):format(snippet.description)
  end
  return ([[
  "%s": {
    "prefix": "%s",
    "body": %s%s
  }]]):format(snippet.trigger, snippet.trigger, body, description_string or "")
end

-- Takes a list of converted snippets for a particular filetype and exports them to a JSON
-- file.
-- @param converted_snippets string[] @A list of strings where each item is a snippet string to be exported
-- @param filetype string @The filetype of the snippets
-- @param output_dir string @The absolute path to the directory to write the snippets to
M.export = function(converted_snippets, filetype, output_dir)
  local snippet_lines = export_utils.snippet_strings_to_lines(converted_snippets, ",", "{", "}")
  print(vim.inspect(snippet_lines))
  local output_path = string.format("%s/%s.json", output_dir, filetype)
  print(output_path)
  utils.write_file(snippet_lines, output_path)
end

return M

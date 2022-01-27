local M = {}

local NodeType = require("snippet_converter.base.node_type")
local base_converter = require("snippet_converter.base.converter")
local utils = require("snippet_converter.utils")
local export_utils = require("snippet_converter.base.export_utils")

M.ultisnips_node_handler = setmetatable({
  [NodeType.TABSTOP] = function(node)
    if not node.transform then
      return base_converter.default_node_handler(M.ultisnips_node_handler)
    end
    local options = node.transform.options
    -- ASCII conversion option
    if options:match("a") then
      error("Cannot convert option 'a' (ascii conversion) in transform node")
    end
    -- Only g, i and m options are valid - ignore the rest
    local converted_options = options:gsub("[^gim]", "")
    return string.format(
      "${%s/%s/%s/%s}",
      node.int,
      node.transform.regex,
      node.transform.format_or_text,
      converted_options
    )
  end,
}, {
  __index = base_converter.default_node_handler(M.ultisnips_node_handler),
})

local list_to_json_string = function(list)
  local lines = vim.split(list, "\n", true)
  local list_items = vim.tbl_map(function(x)
    -- Escape whitespace characters and leave the rest as is
    return ('"%s"'):format(x:gsub("[\t\r\a\b]", {
      ["\t"] = "\\t",
      ["\r"] = "\\r",
      ["\a"] = "\\a",
      ["\b"] = "\\b",
    }))
  end, lines)
  -- Single list item => output a string
  if not list_items[2] then
    return ([["%s"]]):format(list_items[1])
  end
  return ("[%s]"):format(table.concat(list_items, ", "))
end

M.convert = function(snippet, source_format)
  local body
  if source_format == "ultisnips" then
    body = list_to_json_string(base_converter.convert_ast(snippet.body, M.ultisnips_node_handler))
  else
    body = base_converter.convert_ast(snippet.body, base_converter.default_node_handler(nil))
    body = utils.json_encode(vim.fn.split(body, "\n", true))
  end

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

local M = {}

local NodeType = require("snippet_converter.core.node_type")
local base_converter = require("snippet_converter.core.converter")
local err = require("snippet_converter.utils.error")
local io = require("snippet_converter.utils.io")
local export_utils = require("snippet_converter.utils.export_utils")

local node_visitor = {
  [NodeType.TABSTOP] = function(node)
    if not node.transform then
      return "$" .. node.int
    end
    local options = node.transform.options
    -- ASCII conversion option
    if options:match("a") then
      err.raise_converter_error("option 'a' (ascii conversion) in transform node")
    end
    -- Only g, i and m options are valid - ignore the rest
    local converted_options = options:gsub("[^gim]", "")
    return ("${%s/%s/%s/%s}"):format(
      node.int,
      node.transform.regex,
      node.transform.replacement,
      converted_options
    )
  end,
  [NodeType.VISUAL_PLACEHOLDER] = function(_)
    err.raise_converter_error(NodeType.to_string(NodeType.VISUAL_PLACEHOLDER))
  end,
}

M.visit_node = setmetatable(node_visitor, {
  __index = base_converter.visit_node(node_visitor),
})

local escape_chars = function(str)
  -- Escape backslashes (I couldn't get this to work with gsub / regexes)
  local chars = {}
  for i = 1, #str do
    local cur_char = str:sub(i, i)
    if cur_char == "\\" then
      chars[#chars + 1] = "\\"
    end
    chars[#chars + 1] = cur_char
  end

  local item = table.concat(chars)
  -- Surround with quotes and escape whitespace + quote characters
  return ('"%s"'):format(item:gsub('[\t\r\a\b"]', {
    ["\t"] = "\\t",
    ["\r"] = "\\r",
    ["\a"] = "\\a",
    ["\b"] = "\\b",
    ['"'] = '\\"',
  }))
end

local list_to_json_string = function(list)
  local lines = vim.split(list, "\n", true)
  local list_items = vim.tbl_map(escape_chars, lines)

  -- Single list item => output a string
  if not list_items[2] then
    return ("%s"):format(list_items[1])
  end
  return ("[%s]"):format(table.concat(list_items, ", "))
end

M.convert = function(snippet, _, visit_node)
  if snippet.options and snippet.options:match("r") then
    err.raise_converter_error("regex trigger")
  end
  local body = list_to_json_string(
    base_converter.convert_ast(snippet.body, visit_node or M.visit_node)
  )

  local description_string
  if snippet.description then
    description_string = ('\n    "description": %s,'):format(escape_chars(snippet.description))
  end
  local trigger = escape_chars(snippet.trigger)
  local name = (snippet.name and escape_chars(snippet.name)) or trigger
  return ([[
  %s: {
    "prefix": %s,%s
    "body": %s
  }]]):format(name, trigger, description_string or "", body)
end

-- Takes a list of converted snippets for a particular filetype and exports them to a JSON
-- file.
-- @param converted_snippets string[] @A list of strings where each item is a snippet string to be exported
-- @param filetype string @The filetype of the snippets
-- @param output_dir string @The absolute path to the directory to write the snippets to
M.export = function(converted_snippets, filetype, output_path)
  local snippet_lines = export_utils.snippet_strings_to_lines(converted_snippets, ",", { "{" }, "}")
  output_path = export_utils.get_output_file_path(output_path, filetype, "json")
  io.write_file(snippet_lines, output_path)
end

return M

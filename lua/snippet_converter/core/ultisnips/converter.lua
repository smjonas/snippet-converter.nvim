local M = {}

local NodeType = require("snippet_converter.core.node_type")
local base_converter = require("snippet_converter.core.converter")
local io = require("snippet_converter.utils.io")
local export_utils = require("snippet_converter.utils.export_utils")

local node_visitor = {
  [NodeType.TRANSFORM] = function(node)
    return ("/%s/%s/%s"):format(node.regex, node.replacement, node.options)
  end,
  [NodeType.PYTHON_CODE] = function(node)
    return ("`!p %s`"):format(node.code)
  end,
  [NodeType.SHELL_CODE] = function(node)
    return ("`%s`"):format(node.code)
  end,
  [NodeType.VIMSCRIPT_CODE] = function(node)
    return ("`!v %s`"):format(node.code)
  end,
  [NodeType.CHOICE] = function(node)
    return ("${%s|%s|}"):format(node.int, table.concat(node.text, ","))
  end,
  [NodeType.TEXT] = function(node)
    -- Escape ambiguous chars, double backslashes need to be be escaped,
    -- otherwise they will be parsed as a single escaped backslash by UltiSnips
    return node.text:gsub("%$", "\\%$"):gsub("`", "\\`"):gsub([[\\]], [[\\\\]])
  end,
}

M.visit_node = setmetatable(node_visitor, {
  __index = base_converter.visit_node(node_visitor),
})

M.convert = function(snippet)
  local trigger = snippet.trigger
  -- Literal " in trigger
  if trigger:match([["]]) then
    trigger = string.format("!%s!", trigger)
    -- Multi-word or regex trigger
  elseif trigger:match("%s") or snippet.options and snippet.options:match("r") then
    trigger = string.format([["%s"]], trigger)
  end
  -- Description must be quoted
  local description = snippet.description and string.format([[ "%s"]], snippet.description) or ""

  local options = snippet.options and " " .. snippet.options or ""
  -- LuaSnip snippets can have an autotrigger key
  if snippet.luasnip then
    if snippet.luasnip.autotrigger == true then
      options = options .. (snippet.options and "A" or " A")
    end
    snippet.priority = snippet.luasnip.priority
  end
  local body = base_converter.convert_ast(snippet.body, M.visit_node)
  local priority = snippet.priority and ("priority %s\n"):format(snippet.priority) or ""
  local custom_context = snippet.custom_context and ('context "%s"\n'):format(snippet.custom_context) or ""
  -- TODO: remove r from options if only alphanumeric characters

  return string.format(
    "%s%ssnippet %s%s%s\n%s\nendsnippet",
    priority,
    custom_context,
    trigger,
    description,
    options,
    body
  )
end

local HEADER_STRING =
  "# Generated by snippet-converter.nvim (https://github.com/smjonas/snippet-converter.nvim)"

-- Takes a list of converted snippets for a particular filetype,
-- separates them by newlines and exports them to a file.
-- @param converted_snippets string[] @A list of strings where each item is a snippet string to be exported
-- @param filetype string @The filetype of the snippets
-- @param output_dir string @The absolute path to the directory to write the snippets to
-- @param context []? @A table of additional snippet contexts optionally provided the source parser (e.g. global code)
M.export = function(converted_snippets, filetype, output_path, context)
  local output_strings = {}
  if context then
    for i, code in ipairs(context.global_code) do
      local lines = ("global !p\n%s\nendglobal"):format(table.concat(code, "\n"))
      -- Add global python code at the beginning of the output file
      output_strings[i] = lines
    end
    local offset = #output_strings
    for i, snippet in ipairs(converted_snippets) do
      output_strings[i + offset] = snippet
    end
  else
    output_strings = converted_snippets
  end

  local snippet_lines = export_utils.snippet_strings_to_lines(
    output_strings,
    "\n",
    { HEADER_STRING, "" },
    nil
  )
  output_path = ("%s/%s.%s"):format(output_path, filetype, "snippets")
  io.write_file(snippet_lines, output_path)
end

return M

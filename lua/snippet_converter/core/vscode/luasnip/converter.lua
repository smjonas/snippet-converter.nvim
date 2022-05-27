local io = require("snippet_converter.utils.io")
local json_utils = require("snippet_converter.utils.json_utils")
local tbl = require("snippet_converter.utils.table")

local vscode_converter = require("snippet_converter.core.vscode.converter")
local M = setmetatable({}, { __index = vscode_converter })

M.convert = function(snippet, visit_node)
  local result = vscode_converter.convert(snippet, visit_node)
  result.luasnip = tbl.make_default_table({}, "luasnip")
  if result.autotrigger or result.options and result.options:match("A") then
    result.luasnip.autotrigger = true
  end
  if result.priority then
    result.luasnip.priority = result.priority
  end
  if vim.tbl_isempty(result.luasnip) then
    -- Delete if empty
    result.luasnip = nil
  end
  return result
end

-- Takes a list of converted snippets for a particular filetype and exports them to a JSON file.
-- @param converted_snippets table[] @A list of strings where each item is a snippet string to be exported
-- @param filetype string @The filetype of the snippets
-- @param output_dir string @The absolute path to the directory to write the snippets to
M.export = function(converted_snippets, filetype, output_path, _)
  local table_to_export = {}
  -- Also include the luasnip key
  local order = { [1] = {}, [2] = { "prefix", "description", "scope", "body", "luasnip" } }
  for i, snippet in ipairs(converted_snippets) do
    local key = snippet.name or snippet.trigger
    order[1][i] = key
    -- Ignore any other fields
    table_to_export[key] = {
      prefix = snippet.trigger,
      description = snippet.description,
      scope = snippet.scope,
      body = snippet.body,
      luasnip = snippet.luasnip,
    }
  end
  local output_string = json_utils:pretty_print(table_to_export, order, true)
  output_path = ("%s/%s.%s"):format(output_path, filetype, "json")
  io.write_file(vim.split(output_string, "\n"), output_path)
  return output_path
end

return M

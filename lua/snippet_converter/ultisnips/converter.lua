local NodeType = require("snippet_converter.base.node_type")
local Variable = require("snippet_converter.vscode.body_parser").Variable
local base_converter = require("snippet_converter.base.converter")
local utils = require("snippet_converter.utils")

local converter = {}

-- Determines whether the provided snippet can be converted from UltiSnips
-- to other formats (e.g. python interpolation is an UltiSnips-only feature).
function converter.can_convert(snippet, target_engine)
  local body = vim.fn.join(snippet.body, "")
  -- Must not contain interpolation code
  return not body:match("`[^`]*`")
end

local vimscript_variable_handler = setmetatable({
  [Variable.TM_FILENAME] = [[``!v expand('%:t')``]],
  [Variable.TM_FILENAME_BASE] = [[`!v expand('%:t:r')`]],
  [Variable.TM_DIRECTORY] = [[`!v expand('%:p:r')`]],
  [Variable.TM_FILEPATH] = [[`!v expand('%:p')`]],
  [Variable.RELATIVE_FILEPATH] = [[`!v expand('%:p:.')`]],
  [Variable.CLIPBOARD] = [[`!v getreg(v:register)`]],
  [Variable.CURRENT_YEAR] = [[`!v !v strftime('%Y')`]],
  [Variable.CURRENT_YEAR_SHORT] = [[`!v strftime('%y')`]],
  [Variable.CURRENT_MONTH] = [[`!v strftime('%m')`]],
  [Variable.CURRENT_MONTH_NAME] = [[`!v strftime('%B')`]],
  [Variable.CURRENT_MONTH_NAME_SHORT] = [[`!v strftime('%b')`]],
  [Variable.CURRENT_DATE] = [[`!v strftime('%b')`]],
  [Variable.CURRENT_DAY_NAME] = [[`!v strftime('%A')`]],
  [Variable.CURRENT_DAY_NAME_SHORT] = [[`!v strftime('%a')`]],
  [Variable.CURRENT_HOUR] = [[`!v strftime('%H')`]],
  [Variable.CURRENT_MINUTE] = [[`!v strftime('%M')`]],
  [Variable.CURRENT_SECOND] = [[`!v strftime('%S')`]],
  [Variable.CURRENT_SECONDS_UNIX] = [[`!v localtime()`]],
}, {
  __index = function(_, key)
    error("no vimscript handler for variable " .. key)
  end,
})

converter.node_handler = setmetatable({
  [NodeType.VARIABLE] = function(node)
    if node.transform then
      error("Cannot convert variable with transform")
    end
    local var = vimscript_variable_handler[node.var]
    if node.any then
      local any = base_converter.convert_node_recursive(
        node.any,
        base_converter.default_node_handler
      )
      return string.format("${%s:%s}", var, any)
    end
    return var
  end,
}, {
  __index = base_converter.default_node_handler,
})

function converter.convert(snippet)
  -- print(vim.inspect(snippet))
  local trigger = snippet.trigger
  -- Literal " in trigger
  if trigger:match([["]]) then
    trigger = string.format("!%s!", trigger)
    -- Multi-word trigger
  elseif trigger:match("%s") then
    trigger = string.format([["%s"]], trigger)
  end
  local description = ""
  -- Description must be quoted
  if snippet.description then
    description = string.format([[ "%s"]], snippet.description)
  end
  local body = base_converter.convert_ast(snippet.body, converter.node_handler)
  return string.format("snippet %s%s\n%s\nendsnippet", trigger, description, body)
end

-- Takes a list of converted snippets for a particular filetype,
-- separates them by empty lines and exports them to a file.
-- @param converted_snippets string[] @A list of strings where each item is a snippet string to be exported
-- @param filetype string @The filetype of the snippets
-- @param output_dir string @The absolute path to the directory to write the snippets to
converter.export = function(converted_snippets, filetype, output_dir)
  local output_path = string.format("%s/%s.snippets", output_dir, filetype)
  utils.write_file(table.concat(converted_snippets, "\n\n"), output_path)
  print(output_path)
end

return converter

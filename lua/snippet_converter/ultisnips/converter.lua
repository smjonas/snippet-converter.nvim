local NodeType = require "snippet_converter.base.node_type"
local Variable = require("lua.snippet_converter.vscode.body_parser2").Variable
local base_converter = require "snippet_converter.base.converter"

local converter = {}

-- Determines whether the provided snippet can be converted from UltiSnips
-- to other formats (e.g. python interpolation is an UltiSnips-only feature).
function converter.can_convert(snippet, target_engine)
  local body = vim.fn.join(snippet.body, "")
  -- Must not contain interpolation code
  return not body:match "`[^`]*`"
end

local vimscript_variable_handler = setmetatable({
  [Variable.TM_FILENAME] = [[expand('%:t')]],
  [Variable.TM_FILENAME_BASE] = [[expand('%:t:r')]],
  [Variable.TM_DIRECTORY] = [[expand('%:p:r')]],
  [Variable.TM_FILEPATH] = [[expand('%:p')]],
  [Variable.RELATIVE_FILEPATH] = [[expand('%:p:.')]],
  [Variable.CLIPBOARD] = [[getreg(v:register)]],
  [Variable.CURRENT_YEAR] = [[strftime('%Y')]],
  [Variable.CURRENT_YEAR_SHORT] = [[strftime('%y')]],
  [Variable.CURRENT_MONTH] = [[strftime('%m')]],
  [Variable.CURRENT_MONTH_NAME] = [[strftime('%B')]],
  [Variable.CURRENT_MONTH_NAME_SHORT] = [[strftime('%b')]],
  [Variable.CURRENT_DATE] = [[strftime('%b')]],
  [Variable.CURRENT_DAY_NAME] = [[strftime('%A')]],
  [Variable.CURRENT_DAY_NAME_SHORT] = [[strftime('%a')]],
  [Variable.CURRENT_HOUR] = [[strftime('%H')]],
  [Variable.CURRENT_MINUTE] = [[strftime('%M')]],
  [Variable.CURRENT_SECOND] = [[strftime('%S')]],
  [Variable.CURRENT_SECONDS_UNIX] = [[localtime()]],
}, {
  __index = function(_, key)
    error("[UltiSnips converter] no vimscript handler for variable " .. key)
  end,
})

local wrap_in_vimscript = function(val)
  return "`!v" .. val .. "`"
end

converter.node_handler = setmetatable({
  [NodeType.VARIABLE] = function(node)
    if node.transform then
      error "Cannot convert variable with transform"
    end
    local var = wrap_in_vimscript(vimscript_variable_handler[node.var])
    if node.any then
      print(vim.inspect(node.any))
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
  local trigger = snippet.trigger
  -- Literal " in trigger
  if trigger:match [["]] then
    trigger = string.format("!%s!", trigger)
    -- Multi-word trigger
  elseif trigger:match "%s" then
    trigger = string.format([["%s"]], trigger)
  end
  local description = ""
  -- Description must be quoted
  if snippet.description then
    description = string.format([[ "%s"]], snippet.description)
  end
  local body = base_converter.convert_tree(snippet.body, converter.node_handler)
  return string.format("snippet %s%s\n%s\nendsnippet", trigger, description, body)
end

return converter

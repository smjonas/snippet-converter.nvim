local NodeType = require("snippet_converter.core.node_type")
local Variable = require("snippet_converter.core.vscode.body_parser").Variable

local M = {}

M.convert_node_recursive = function(node, node_visitor)
  local result = {}
  local is_non_terminal_node = node.type ~= nil
  if is_non_terminal_node then
    result[#result + 1] = node_visitor[node.type](node)
  else
    error("node.type is nil " .. vim.inspect(node), 0)
  end
  return table.concat(result)
end

M.convert_ast = function(ast, node_visitor)
  local result = {}
  for _, node in ipairs(ast) do
    result[#result + 1] = M.convert_node_recursive(node, node_visitor)
  end
  return table.concat(result)
end

-- Converts a VSCode variable to equivalent VimScript code
local convert_variable = setmetatable({
  [Variable.TM_FILENAME] = [[`!v expand('%:t')`]],
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
    error("failed to convert unknown variable " .. key)
  end,
})

M.visit_node = function(custom_node_visitor)
  local default
  default = setmetatable({
    [NodeType.TABSTOP] = function(node)
      if node.transform then
        return string.format("${%s%s}", node.int, node.transform)
      end
      return "$" .. node.int
    end,
    [NodeType.PLACEHOLDER] = function(node)
      return string.format(
        "${%s:%s}",
        node.int,
        -- The 'any' node consists of a variable number of subnodes
        M.convert_ast(node.any, custom_node_visitor or default)
      )
    end,
    [NodeType.CHOICE] = function(node)
      local text_string = table.concat(node.text, ",")
      return string.format("${%s|%s|}", node.int, text_string)
    end,
    [NodeType.VARIABLE] = function(node)
      if node.transform then
        error("cannot convert variable with transform")
      end
      local var = convert_variable[node.var]
      if node.any then
        local any = M.convert_node_recursive(node.any, M.visit_node)
        return string.format("${%s:%s}", var, any)
      end
      return var
    end,
    [NodeType.TEXT] = function(node)
      return node.text
    end,
  }, {
    __index = function(_, node_type)
      error(("conversion of %s is not supported"):format(NodeType.to_string(node_type)), 0)
    end,
  })
  return default
end

return M
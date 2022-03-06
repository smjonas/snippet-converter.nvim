local M = {}

local NodeType = require("snippet_converter.core.node_type")
local Variable = require("snippet_converter.core.vscode.body_parser").Variable
local err = require("snippet_converter.utils.error")

M.convert_ast = function(ast, node_visitor)
  local result = {}
  for _, node in ipairs(ast) do
    result[#result + 1] = node_visitor[node.type](node)
  end
  return table.concat(result)
end

-- TODO: make SnipMate a subclass of UltiSnips
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
  assert(custom_node_visitor)
  local default
  default = setmetatable({
    [NodeType.TABSTOP] = function(node)
      if node.transform then
        -- This should be handled inside the format-specific node visitor
        error("could not convert transform node inside tabstop")
      end
      return "$" .. node.int
    end,
    [NodeType.PLACEHOLDER] = function(node)
      assert(custom_node_visitor)
      return string.format(
        "${%s:%s}",
        node.int,
        -- The 'any' node consists of a variable number of subnodes
        M.convert_ast(node.any, custom_node_visitor or default)
      )
    end,
    [NodeType.VISUAL_PLACEHOLDER] = function(node)
      if not node.text then
        return "${VISUAL}"
      else
        -- TODO: visual_placeholder #3
        return ("${VISUAL:%s}"):format(node.text)
      end
    end,
    [NodeType.CHOICE] = function(node)
      local text_string = table.concat(node.text, ",")
      return string.format("${%s|%s|}", node.int, text_string)
    end,
    -- TODO: move to UltiSnips converter
    [NodeType.VARIABLE] = function(node)
      if node.transform then
        err.raise_converter_error("transform")
      end
      local var = convert_variable[node.var]
      if node.any then
        local any = M.convert_ast(node.any, custom_node_visitor or default)
        return string.format("${%s:%s}", var, any)
      end
      return var
    end,
    [NodeType.TEXT] = function(node)
      return node.text
    end,
  }, {
    __index = function(_, node_type)
      err.raise_converter_error(NodeType.to_string(node_type))
    end,
  })
  return default
end

return M

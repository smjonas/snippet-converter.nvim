local base_converter = require("snippet_converter.core.converter")
local vscode_converter = require("snippet_converter.core.vscode.converter")
local NodeType = require("snippet_converter.core.node_type")
local Variable = require("snippet_converter.core.vscode.vsnip.body_parser")

-- vsnip supports a superset of VSCode snippets
local M = setmetatable({}, { __index = vscode_converter })

local node_visitor = {
  [NodeType.VARIABLE] = function(node)
    if node.var == Variable.VIM then
      if node.any then
        local any = base_converter.convert_ast(node.any, M.visit_node)
        return ("${VIM:%s}"):format(result)
      else
        return "$VIM"
      end
    end
    -- Fallback case
    return vscode_converter.visit_node(node)
  end,
}

M.visit_node = setmetatable(node_visitor, {
  __index = vscode_converter.visit_node(node_visitor),
})

M.convert = function(snippet, source_format)
  return vscode_converter.convert(snippet, source_format, M.visit_node)
end

return M

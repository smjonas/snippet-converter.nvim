local vscode_converter = require("snippet_converter.core.vscode.converter")
local NodeType = require("snippet_converter.core.node_type")

-- vsnip supports a superset of VSCode snippets
local M = setmetatable({}, { __index = vscode_converter })

local node_visitor = setmetatable({
  [NodeType.VIMSCRIPT_CODE] = function(node)
    if node.code then
      return ("${VIM:%s}"):format(node.code)
    else
      return "$VIM"
    end
  end,
}, { __index = vscode_converter.node_visitor })

M.convert = function(snippet)
  return vscode_converter.convert(snippet, node_visitor)
end

return M

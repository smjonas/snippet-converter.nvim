local NodeType = require "snippet_converter.base.node_type"

local converter = {}

converter.convert_node_recursive = function(node, node_handler)
  local result = {}
  local is_non_terminal_node = node.type ~= nil
  if is_non_terminal_node then
    result[#result + 1] = node_handler[node.type](node)
  else
    error("node.type is nil " .. vim.inspect(node))
  end
  return table.concat(result)
end

converter.convert_tree = function(ast, node_handler)
  local result = {}
  print(vim.inspect(ast))
  for _, node in ipairs(ast) do
    result[#result + 1] = converter.convert_node_recursive(node, node_handler)
  end
  return table.concat(result)
end

converter.default_node_handler = setmetatable({
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
      converter.convert_node_recursive(node.any, converter.default_node_handler)
    )
  end,
  [NodeType.CHOICE] = function(node)
    local text_string = table.concat(node.text, ",")
    return string.format("${%s|%s|}", node.int, text_string)
  end,
  [NodeType.TEXT] = function(node)
    return node.text
  end,
}, {
  __index = function(_, key)
    error("[snippet_converter]: no handler found for node " .. key)
  end,
})

return converter

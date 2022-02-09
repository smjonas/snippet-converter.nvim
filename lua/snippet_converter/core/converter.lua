local NodeType = require("snippet_converter.core.node_type")

local converter = {}

converter.convert_node_recursive = function(node, node_visitor)
  local result = {}
  local is_non_terminal_node = node.type ~= nil
  if is_non_terminal_node then
    result[#result + 1] = node_visitor[node.type](node)
  else
    error("node.type is nil " .. vim.inspect(node), 0)
  end
  return table.concat(result)
end

converter.convert_ast = function(ast, node_visitor)
  local result = {}
  for _, node in ipairs(ast) do
    result[#result + 1] = converter.convert_node_recursive(node, node_visitor)
  end
  return table.concat(result)
end

converter.visit_node = function(custom_node_visitor)
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
        converter.convert_ast(node.any, custom_node_visitor or default)
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
    __index = function(_, node_type)
      error(("conversion of %s is not supported"):format(NodeType.to_string(node_type)), 0)
    end,
  })
  return default
end

return converter

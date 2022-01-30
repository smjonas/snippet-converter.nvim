local Node = {}

local Type = {
  ROOT_NODE = 1,
  HL_TEXT_NODE = 2,
  MULTI_HL_TEXT_NODE = 3,
  EXPANDABLE_NODE = 4,
  KEYMAP_NODE = 5,
  NEW_LINE = 6,
}

local Style = {
  CENTERED = 1,
  LEFT_PADDING = 2,
}

Node.RootNode = function(child_nodes)
  return {
    type = Type.ROOT_NODE,
    child_nodes = child_nodes,
  }
end

Node.HlTextNode = function(text, hl_group, style)
  return {
    type = Type.HL_TEXT_NODE,
    text = text,
    hl_group = hl_group,
    style = style,
  }
end

Node.MultiHlTextNode = function(texts, hl_groups, style)
  return {
    type = Type.MULTI_HL_TEXT_NODE,
    texts = texts,
    hl_groups = hl_groups,
    style = style,
  }
end

Node.ExpandableNode = function(parent_node, child_node)
  return {
    type = Type.EXPANDABLE_NODE,
    parent_node = parent_node,
    child_node = child_node,
    is_expanded = false,
  }
end

Node.KeymapNode = function(node, lhs, callback)
  return {
    type = Type.KEYMAP_NODE,
    node = node,
    keymap = { lhs = lhs, callback = callback },
  }
end

Node.NewLine = function()
  return {
    type = Type.NEW_LINE,
  }
end

Node.Type = Type
Node.Style = Style
return Node

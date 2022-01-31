local Node = {}

local Type = {
  ROOT = 1,
  HL_TEXT = 2,
  MULTI_HL_TEXT = 3,
  EXPANDABLE = 4,
  KEYMAP = 5,
  NEW_LINE = 6,
}

local Style = {
  CENTERED = 1,
}

Node.RootNode = function(child_nodes)
  return {
    type = Type.ROOT,
    child_nodes = child_nodes,
  }
end

Node.HlTextNode = function(text, hl_group, style)
  return {
    type = Type.HL_TEXT,
    text = text,
    hl_group = hl_group,
    style = style,
  }
end

Node.MultiHlTextNode = function(texts, hl_groups, style)
  return {
    type = Type.MULTI_HL_TEXT,
    texts = texts,
    hl_groups = hl_groups,
    style = style,
  }
end

Node.ExpandableNode = function(parent_node, child_node)
  return {
    type = Type.EXPANDABLE,
    parent_node = parent_node,
    child_node = child_node,
    is_expanded = false,
  }
end

Node.KeymapNode = function(node, lhs, callback)
  return {
    type = Type.KEYMAP,
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

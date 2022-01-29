local Node = {}

local Type = {
  HL_TEXT_NODE = 1,
  NESTED_NODE = 2,
}

local Style = {
  CENTERED = 1,
}

Node.HlTextNode = function(text, hl_group, style)
  return {
    type = Type.HL_TEXT_NODE,
    text = text,
    hl_group = hl_group,
    style = style,
  }
end

Node.NestedNode = function(child_nodes)
  return {
    type = Type.NESTED_NODE,
    child_nodes = child_nodes,
  }
end

Node.Type = Type
Node.Style = Style
return Node

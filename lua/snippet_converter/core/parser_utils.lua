local M = {}

local NodeType = require("snippet_converter.core.node_type")

M.new_inner_node = function(type, node)
  node.type = type
  return node
end

M.expect = function(state, chars)
  local len = chars:len()
  if not state.input or state.input:len() < len then
    M.raise_backtrack_error("no chars to skip, expected '" .. chars .. "'")
  end
  if state.input:sub(1, len) ~= chars then
    M.raise_backtrack_error("expected '" .. chars .. "'")
  end
  state.input = state.input:sub(len + 1)
end

M.peek = function(state, chars)
  if not state.input then
    return nil
  end
  local prefix = state.input:sub(1, chars:len())
  if prefix == chars then
    M.expect(state, chars)
    return prefix
  end
end

M.peek_pattern = function(state, pattern)
  local chars_matched, _ = state.input:match(pattern)
  if chars_matched then
    M.expect(state, chars_matched)
    return chars_matched
  end
end

M.parse_pattern = function(state, pattern)
  local match = state.input:match("^" .. pattern)
  if not match then
    M.raise_backtrack_error(string.format("pattern %s not matched", pattern))
  end
  M.expect(state, match)
  return match
end

M.pattern = function(pattern_string)
  return function(state)
    return M.parse_pattern(state, pattern_string)
  end
end

M.parse_bracketed = function(state, parse_fn)
  local has_bracket = M.peek(state, "{")
  local result = parse_fn(state)
  if not has_bracket or M.peek(state, "}") then
    return true, result
  end
  return false, result
end

M.parse_escaped_text = function(state, escape_pattern, break_pattern)
  local input = state.input
  if input == "" then
    M.raise_backtrack_error("parse_escaped_text: input is nil or empty")
  end
  local parsed_text = {}
  local i = 1
  local cur_char = input:sub(1, 1)
  local begin_escape
  while cur_char ~= "" do
    if not begin_escape then
      begin_escape = cur_char == [[\]]
      if not begin_escape and cur_char:match(break_pattern or escape_pattern) then
        break
      end
      parsed_text[#parsed_text + 1] = cur_char
    else
      if cur_char:match(escape_pattern) then
        -- Overwrite the backslash
        parsed_text[#parsed_text] = cur_char
      else
        parsed_text[#parsed_text + 1] = cur_char
      end
      begin_escape = false
    end
    i = i + 1
    cur_char = state.input:sub(i, i)
  end
  state.input = input:sub(i)
  return table.concat(parsed_text)
end

M.raise_backtrack_error = function(msg)
  -- Add a header so we can differentiate between an error that should cause the parser to
  -- backtrack and an actual syntax error such as an unsupported feature.
  error("BACKTRACK " .. msg, 0)
end

M.backtrack = function(state, ast, prev_input, parse_any_ptr)
  state.input = prev_input
  local chars = {}
  local ok, result
  while not ok do
    -- Parse the next chars as a text node, then try from that position
    if state.input == "" then
      ast[#ast + 1] = M.new_inner_node(NodeType.TEXT, { text = prev_input })
      break
    end
    chars[#chars + 1] = state.input:sub(1, 1)
    state.input = state.input:sub(2)
    local prev = state.input
    ok, result = pcall(parse_any_ptr, state)
    if ok then
      ast[#ast + 1] = M.new_inner_node(NodeType.TEXT, { text = table.concat(chars) })
      ast[#ast + 1] = result
      break
    else
      state.input = prev
    end
  end
  local i = #ast
  while i >= 2 do
    -- Merge adjacent text nodes from the right
    if ast[i - 1].type == NodeType.TEXT and ast[i].type == NodeType.TEXT then
      ast[i - 1].text = ast[i - 1].text .. ast[i].text
      table.remove(ast, i)
    end
    i = i - 1
  end
  return ast
end

return M

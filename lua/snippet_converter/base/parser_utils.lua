local M = {}

M.new_inner_node = function(type, node)
  node.type = type
  return node
end

M.raise_parse_error = function(state, description)
  error(string.format("%s at '%s' (source '%s')", description, state.input, state.source))
end

M.expect = function(state, chars)
  local len = chars:len()
  if not state.input or state.input:len() < len then
    M.raise_parse_error(state, "no chars to skip, expected '" .. chars .. "'")
  end
  if state.input:sub(1, len) ~= chars then
    M.raise_parse_error(state, "expected '" .. chars .. "'")
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
  -- TODO: can this be assumed to be non-nil?
  if not state.input then
    error("parse_pattern: input is nil")
  end
  local match = state.input:match("^" .. pattern)
  if not match then
    M.raise_parse_error(state, string.format("pattern %s not matched", pattern))
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

M.parse_escaped_text = function(state, escape_pattern)
  local input = state.input
  if input == "" then
    M.raise_parse_error("parse_escaped_text: input is nil or empty")
  end
  local parsed_text = {}
  local i = 1
  local cur_char = input:sub(1, 1)
  local begin_escape
  while cur_char ~= "" do
    if not begin_escape then
      begin_escape = cur_char == [[\]]
      if not begin_escape and cur_char:match(escape_pattern) then
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

return M

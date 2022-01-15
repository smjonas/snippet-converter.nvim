local NodeType = require("snippet_converter.base.node_type")

local Variable = {
  TM_CURRENT_LINE = "TM_CURRENT_LINE",
  TM_CURRENT_WORD = "TM_CURRENT_WORD",
  TM_LINE_INDEX = "TM_LINE_INDEX",
  TM_LINE_NUMBER = "TM_LINE_NUMBER",
  TM_FILENAME = "TM_FILENAME",
  TM_FILENAME_BASE = "TM_FILENAME_BASE",
  TM_DIRECTORY = "TM_DIRECTORY",
  TM_FILEPATH = "TM_FILEPATH",
  RELATIVE_FILEPATH = "RELATIVE_FILEPATH",
  CLIPBOARD = "CLIPBOARD",
  WORKSPACE_NAME = "WORKSPACE_NAME",
  WORKSPACE_FOLDER = "WORKSPACE_FOLDER",
  CURRENT_YEAR = "CURRENT_YEAR",
  CURRENT_YEAR_SHORT = "CURRENT_YEAR_SHORT",
  CURRENT_MONTH = "CURRENT_MONTH",
  CURRENT_MONTH_NAME = "CURRENT_MONTH_NAME",
  CURRENT_MONTH_NAME_SHORT = "CURRENT_MONTH_NAME_SHORT",
  CURRENT_DATE = "CURRENT_DATE",
  CURRENT_DAY_NAME = "CURRENT_DAY_NAME",
  CURRENT_DAY_NAME_SHORT = "CURRENT_DAY_NAME_SHORT",
  CURRENT_HOUR = "CURRENT_HOUR",
  CURRENT_MINUTE = "CURRENT_MINUTE",
  CURRENT_SECOND = "CURRENT_SECOND",
  CURRENT_SECONDS_UNIX = "CURRENT_SECONDS_UNIX",
  RANDOM = "RANDOM",
  RANDOM_HEX = "RANDOM_HEX",
  UUID = "UUID",
  BLOCK_COMMENT_START = "BLOCK_COMMENT_START",
  BLOCK_COMMENT_END = "BLOCK_COMMENT_END",
  LINE_COMMENT = "LINE_COMMENT",
}
local variable_tokens = vim.tbl_values(Variable)

local format_modifier_tokens = {
  "upcase",
  "downcase",
  "capitalize",
  "camelcase",
  "pascalcase",
}

local new_inner_node = function(type, node)
  node.type = type
  return node
end

local raise_parse_error = function(state, description)
  error(string.format("%s: %s at input '%s'", state.cur_parser, description, state.input))
end

local expect = function(state, chars)
  local len = chars:len()
  if state.input == nil or state.input:len() < len then
    raise_parse_error(state, "no chars to skip")
  end
  if state.input:sub(1, len) ~= chars then
    raise_parse_error(state, "expected '" .. chars .. "'")
  end
  state.input = state.input:sub(len + 1)
end

local peek = function(state, chars)
  if state.input == nil then
    return nil
  end
  local prefix = state.input:sub(1, chars:len())
  if prefix == chars then
    expect(state, chars)
    return prefix
  end
end

local peek_pattern = function(state, pattern)
  local chars_matched, _ = state.input:match(pattern)
  if chars_matched then
    expect(state, chars_matched)
    return chars_matched
  end
end

local parse_pattern = function(state, pattern)
  -- TODO: can this be assumed to be non-nil?
  if state.input == nil then
    error "parse_pattern: input is nil"
  end
  local match = state.input:match("^" .. pattern)
  if match == nil then
    raise_parse_error(state, string.format("pattern %s not matched", pattern))
  end
  expect(state, match)
  return match
end

local pattern = function(pattern_string)
  return function(state)
    return parse_pattern(state, pattern_string)
  end
end

local var_pattern = "[_a-zA-Z][_a-zA-Z0-9]*"
local options_pattern = "[^}]*"
local parse_int = pattern "[0-9]+"

local parse_escaped_text = function(state, escape_pattern)
  local input = state.input
  if input == "" then
    raise_parse_error "parse_escaped_text: input is nil or empty"
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
    elseif cur_char:match(escape_pattern) then
      -- Overwrite the backslash
      parsed_text[#parsed_text] = cur_char
      begin_escape = false
    end
    i = i + 1
    cur_char = state.input:sub(i, i)
  end
  state.input = input:sub(i)
  return table.concat(parsed_text)
end

local parse_text = function(state)
  return parse_escaped_text(state, "[%$}\\]")
end

-- TODO
local parse_if = parse_text
local parse_else = parse_text

local parse_escaped_choice_text = function(state)
  return parse_escaped_text(state, "[%$}\\,|]")
end

-- Parses a JavaScript regex
local parse_regex = function(state)
  return parse_escaped_text(state, "[/]")
end

local parse_format_modifier = function(state)
  local format_modifier = parse_pattern(state, "[a-z]+")
  if not vim.tbl_contains(format_modifier_tokens, format_modifier) then
    error("parse_format_modifier: invalid modifier " .. format_modifier)
  end
  return format_modifier
end

local parse_bracketed = function(state, parse_fn)
  local has_bracket = peek(state, "{")
  local result = parse_fn(state)
  if not has_bracket or peek(state, "}") then
    return true, result
  end
  return false, result
end

-- starts at the second char
local parse_format = function(state)
  local int_only, int = parse_bracketed(state, parse_int)
  if int_only then
    -- format 1 / 2
    return new_inner_node(NodeType.FORMAT, { int = int })
  else
    local format_modifier, _if, _else
    if peek(state, ":/") then
      -- format 3
      format_modifier = parse_format_modifier(state)
    else
      if peek(state, ":+") then
        -- format 4
        _if = parse_if(state)
      elseif peek(state, ":?") then
        -- format 5
        _if = parse_if(state)
        expect(state, ":")
        _else = parse_else(state)
      elseif peek(state, ":") then
        -- format 6 / 7
        peek(state, "-")
        _else = parse_else(state)
      end
    end
    expect(state, "}")
    return new_inner_node(NodeType.FORMAT, {
      int = int,
      format_modifier = format_modifier,
      _if = _if,
      _else = _else,
    })
  end
end

local parse_format_or_text = function(state)
  if peek(state, "$") then
    return parse_format(state)
  else
    return parse_text(state)
  end
end

local parse_transform = function(state)
  expect(state, "/")
  local regex = parse_regex(state)
  expect(state, "/")
  local format_or_text = { parse_format_or_text(state) }
  while not peek(state, "/") do
    format_or_text[#format_or_text + 1] = parse_format_or_text(state)
  end
  local options = parse_pattern(state, options_pattern)
  return { regex = regex, format_or_text = format_or_text, options = options }
end

local parse_any
local parse_placeholder_any = function(state)
  state.cur_parser = "parse_placeholder_any"
  local any = parse_any(state)
  expect(state, "}")
  return any
end

local parse_choice_text = function(state)
  local text = { parse_escaped_choice_text(state) }
  while peek(state, ",") do
    text[#text + 1] = parse_escaped_choice_text(state)
  end
  expect(state, "|}")
  return text
end

-- starts at char after '$', or after '{' if got_bracket is true
local parse_variable = function(state, got_bracket)
  local var = parse_pattern(state, var_pattern)
  if not vim.tbl_contains(variable_tokens, var) then
    error("parse_variable: invalid token " .. var)
  end
  if not got_bracket or peek(state, "}") then
    -- variable 1 / 2
    return new_inner_node(NodeType.VARIABLE, { var = var })
  end
  if peek(state, ":") then
    local any = parse_any(state)
    -- variable 3
    return new_inner_node(NodeType.VARIABLE, { var = var, any = any })
  end
  local transform = parse_transform(state)
  expect(state, "}")
  -- variable 4
  return new_inner_node(NodeType.VARIABLE, { var = var, transform = transform })
end

-- starts after the int
local parse_tabstop_transform = function(state)
  if peek(state, "}") then
    -- tabstop 2
    return nil
  end
  local transform = parse_transform(state)
  expect(state, "}")
  -- tabstop 3
  return transform
end

parse_any = function(state)
  if peek(state, "$") then
    local got_bracket = peek(state, "{")
    local int = peek_pattern(state, "^%d+")
    if int ~= nil then
      if not got_bracket then
        -- tabstop 1
        return new_inner_node(NodeType.TABSTOP, { int = int })
      elseif peek(state, ":") then
        local any = parse_placeholder_any(state)
        return new_inner_node(NodeType.PLACEHOLDER, { int = int, any = any })
      elseif peek(state, "|") then
        local text = parse_choice_text(state)
        return new_inner_node(NodeType.CHOICE, { int = int, text = text })
      else
        local transform = parse_tabstop_transform(state)
        -- transform may be nil
        return new_inner_node(NodeType.TABSTOP, { int = int, transform = transform })
      end
    else
      return parse_variable(state, got_bracket)
    end
  else
    state.cur_parser = "text"
    local prev_input = state.input
    local text = parse_text(state)
    if state.input == prev_input then
      state.input = ""
    else
      return { text = text }
    end
  end
end

local parser = {
  Variable = Variable
}

parser.parse = function(input)
  local state = {
    input = input,
  }
  local tree = {}
  while state.input ~= nil and state.input ~= "" do
    tree[#tree + 1] = parse_any(state)
  end
  return tree
end

return parser

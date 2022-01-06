local variable_tokens = {
  "TM_SELECTED_TEXT",
  "TM_CURRENT_LINE",
  "TM_CURRENT_WORD",
  "TM_LINE_INDEX",
  "TM_LINE_NUMBER",
  "TM_FILENAME",
  "TM_FILENAME_BASE",
  "TM_DIRECTORY",
  "TM_FILEPATH",
  "RELATIVE_FILEPATH",
  "CLIPBOARD",
  "WORKSPACE_NAME",
  "WORKSPACE_FOLDER",
  "CURRENT_YEAR",
  "CURRENT_MONTH",
  "CURRENT_MONTH_NAME_SHORT",
  "CURRENT_DAY_NAME",
  "CURRENT_HOUR",
  "CURRENT_SECOND",
  "RANDOM_HEX",
  "BLOCK_COMMENT_END",
}

local format_modifier_tokens = {
  "upcase",
  "downcase",
  "capitalize",
  "camelcase",
  "pascalcase",
}

local new_inner_node = function(tag, node)
  node.tag = tag
  return node
end

local expect_chars = function(state, chars)
  local len = chars:len()
  if state.input == nil or state.input:len() < len then
    error "skip_chars: no chars to skip"
  end
  state.input = state.input:sub(len + 1)
end

local peek_chars = function(state, chars)
  -- print(1)
  -- print(state.input)
  local len = chars:len()
  -- print("'" .. state.input:sub(1, len) .. "'")
  -- print("'" .. chars .. "'")
  local chars_matched = state.input:sub(1, len) == chars
  if chars_matched then
    state.input = state.input:sub(len)
    expect_chars(state, chars)
    return true
  end
end

local raise_parse_error = function(state, description)
  error(string.format("%s: %s at input '%s'", state.cur_parser, description, state.input))
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
  expect_chars(state, match)
  return match
end

local pattern = function(pattern_string)
  return function(state)
    return parse_pattern(state, pattern_string)
  end
end

local parse_var = pattern "[_a-zA-Z][_a-zA-Z0-9]*"
local parse_int = pattern "[0-9]+"
local parse_text = pattern "[^%$%}]+"

-- TODO
local parse_regex = parse_text
local parse_options = parse_regex
local parse_if = parse_text
local parse_else = parse_text

local parse_format_modifier = function(state)
  local format_modifier = parse_pattern(state, "[a-z]+")
  if not vim.tbl_contains(format_modifier_tokens, format_modifier) then
    error("parse_format_modifier: invalid modifier " .. format_modifier)
  end
  return format_modifier
end

local parse_surrounded = function(state, parse_fn)
  local has_bracket = peek_chars(state, "{")
  local result = parse_fn(state)
  if not has_bracket or peek_chars "}" then
    return true, result
  end
  return false, result
end

-- starts at the second char
local parse_format = function(state)
  local int_only, int = parse_surrounded(state, parse_int)
  if int_only then
    -- format 1 / 2
    return new_inner_node("format", { int })
  else
    local format_modifier, _if, _else
    if peek_chars(state, ":/") then
      -- format 3
      format_modifier = parse_format_modifier(state)
    else
      if peek_chars(state, ":+") then
        -- format 4
        _if = parse_if(state)
      elseif peek_chars(state, ":?") then
        -- format 5
        _if = parse_if(state)
        expect_chars(state, ":")
        _else = parse_else(state)
      elseif peek_chars(state, ":") then
        -- format 6 / 7
        peek_chars(state, "-")
        _else = parse_else(state)
      end
    end
    expect_chars(state, "}")
    return new_inner_node("format", {
      int,
      format_modifier = format_modifier,
      _if = _if,
      _else = _else,
    })
  end
end

local parse_format_or_text = function(state)
  if peek_chars(state, "$") then
    return parse_format(state)
  else
    return parse_text(state)
  end
end

local parse_transform = function(state)
  expect_chars(state, "/")
  local regex = parse_regex(state)
  expect_chars(state, "/")
  local format_or_text = { parse_format_or_text(state) }
  while not peek_chars "/" do
    format_or_text[#format_or_text + 1] = parse_format_or_text(state)
  end
  local options = parse_options(state)
  return new_inner_node("transform", { regex, format_or_text, options })
end

local parse_any
local parse_placeholder_any = function(state)
  state.cur_parser = "parse_placeholder_any"
  local any = parse_any(state)
  expect_chars(state, "}")
  return any
end

local parse_choice_text = function(state)
  local text = { parse_text(state) }
  while peek_chars(state, ",") do
    text[#text + 1] = parse_text(state)
  end
  expect_chars(state, "|}")
  return text
end

-- starts at second char
local parse_variable = function(state)
  local var_only, var = parse_surrounded(state, parse_var)
  if not vim.tbl_contains(variable_tokens, var) then
    error("parse_variable: invalid token " .. var)
  end
  if var_only then
    -- variable 1 / 2
    return new_inner_node("variable", { var })
  elseif peek_chars(state, ":") then
    local any = parse_any(state)
    expect_chars(state, "}")
    -- variable 3
    return new_inner_node("variable", { var, any })
  else
    local transform = parse_transform(state)
    expect_chars(state, "}")
    -- variable 4
    return new_inner_node("variable", { var, transform })
  end
end

-- starts at second char
local parse_tabstop = function(state)
  local int_only, int = parse_surrounded(state, parse_int)
  if int_only then
    -- tabstop 1 / 2
    return new_inner_node("tabstop", { int })
  else
    local transform = parse_transform(state)
    expect_chars(state, "}")
    -- tabstop 3
    return new_inner_node("tabstop", { int, transform })
  end
end

parse_any = function(state)
  print("BEFO", state.input)
  if peek_chars(state, "$") then
    print("here", state.input)
    if peek_chars(state, "{") then
      print("here2")
      local int = parse_int(state)
      if peek_chars(state, ":") then
        print("here3")
        local any = parse_placeholder_any(state)
        return new_inner_node("placeholder", { int, any })
      elseif peek_chars(state, "|") then
        local text = parse_choice_text(state)
        return new_inner_node("choice", { int, text })
      end
    else
      return parse_tabstop(state)
    end
  else
    state.cur_parser = "text"
    local text = parse_text(state)
    return new_inner_node("text", { text })
  end
end

local parser = {}

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

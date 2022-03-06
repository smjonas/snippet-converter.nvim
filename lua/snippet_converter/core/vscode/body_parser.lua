local p = require("snippet_converter.core.parser_utils")
local NodeType = require("snippet_converter.core.node_type")

-- Grammar in EBNF (see https://code.visualstudio.com/docs/editor/userdefinedsnippets#_grammar)
-- any                ::= tabstop | placeholder | choice | variable | text
-- tabstop            ::= '$' int
--                        | '${' int '}'
--                        | '${' int  transform '}'
-- placeholder        ::= '${' int ':' any '}'
-- choice             ::= '${' int '|' text (',' text)* '|}'
-- variable           ::= '$' var | '${' var '}'
--                        | '${' var ':' any '}'
--                        | '${' var transform '}'
-- transform          ::= '/' regex '/' replacement '/' options
-- format             ::= '$' int | '${' int '}'
--                        | '${' int ':' '/upcase' | '/downcase' | '/capitalize' | '/camelcase' | '/pascalcase' '}'
--                        | '${' int ':+' if '}'
--                        | '${' int ':?' if ':' else '}'
--                        | '${' int ':-' else '}' | '${' int ':' else '}'
-- regex              ::= JavaScript Regular Expression value (ctor-string)
-- replacement        ::= text
-- options            ::= text
-- var                ::= [_a-zA-Z] [_a-zA-Z0-9]*
-- int                ::= [0-9]+
-- text               ::= .*

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

local M = {
  Variable = Variable,
  variable_tokens = variable_tokens,
}

local format_modifier_tokens = {
  "upcase",
  "downcase",
  "capitalize",
  "camelcase",
  "pascalcase",
}

local var_pattern = "[_a-zA-Z][_a-zA-Z0-9]*"
-- TODO: move
local options_pattern = "[^}]*"
local parse_int = p.pattern("[0-9]+")

local parse_text = function(state)
  -- TODO: reword
  -- '%', '$' and '\' must be escaped; '}' signals the end of the text
  return p.parse_escaped_text(state, "[%$}\\]")
end

-- TODO
local parse_if = parse_text
local parse_else = parse_text

local parse_escaped_choice_text = function(state)
  return p.parse_escaped_text(state, "[%$}\\,|]")
end

-- Parses a JavaScript regex
local parse_regex = function(state)
  return p.parse_escaped_text(state, "[/]")
end

local parse_format_modifier = function(state)
  local format_modifier = p.parse_pattern(state, "[a-z]+")
  if not vim.tbl_contains(format_modifier_tokens, format_modifier) then
    error("parse_format_modifier: invalid modifier " .. format_modifier)
  end
  return format_modifier
end

-- Starts at the second char
local parse_format = function(state)
  local int_only, int = p.parse_bracketed(state, parse_int)
  if int_only then
    -- format 1 / 2
    return p.new_inner_node(NodeType.FORMAT, { int = int })
  else
    local format_modifier, _if, _else
    if p.peek(state, ":/") then
      -- format 3
      format_modifier = parse_format_modifier(state)
    else
      if p.peek(state, ":+") then
        -- format 4
        _if = parse_if(state)
      elseif p.peek(state, ":?") then
        -- format 5
        _if = parse_if(state)
        p.expect(state, ":")
        _else = parse_else(state)
      elseif p.peek(state, ":") then
        -- format 6 / 7
        p.peek(state, "-")
        _else = parse_else(state)
      end
    end
    p.expect(state, "}")
    return p.new_inner_node(NodeType.FORMAT, {
      int = int,
      format_modifier = format_modifier,
      _if = _if,
      _else = _else,
    })
  end
end

local parse_format_or_text = function(state)
  if p.peek(state, "$") then
    return parse_format(state)
  else
    return p.parse_escaped_text(state, "[%$}\\]", "/")
  end
end

local parse_transform = function(state)
  p.expect(state, "/")
  local regex = parse_regex(state)
  p.expect(state, "/")
  local format_or_text = { parse_format_or_text(state) }
  while not p.peek(state, "/") do
    format_or_text[#format_or_text + 1] = parse_format_or_text(state)
  end
  local options = p.parse_pattern(state, options_pattern)
  return p.new_inner_node(
    NodeType.TRANSFORM,
    { regex = regex, format_or_text = format_or_text, options = options }
  )
end

local parse_any
local parse_placeholder_any = function(state)
  local any = { parse_any(state) }
  local pos = 2
  while state.input:sub(1, 1) ~= "}" do
    any[pos] = parse_any(state)
    pos = pos + 1
  end
  p.expect(state, "}")
  return any
end

local parse_choice_text = function(state)
  local text = { parse_escaped_choice_text(state) }
  while p.peek(state, ",") do
    text[#text + 1] = parse_escaped_choice_text(state)
  end
  p.expect(state, "|}")
  return text
end

-- Expose to subclasses.
-- Starts at char after '$', or after '{' if got_bracket is true
M.parse_variable = function(state, got_bracket, var_tokens)
  local var = p.parse_pattern(state, var_pattern)
  if not vim.tbl_contains(var_tokens or M.variable_tokens, var) then
    error("parse_variable: invalid token " .. var)
  end
  if not got_bracket or p.peek(state, "}") then
    -- variable 1 / 2
    return p.new_inner_node(NodeType.VARIABLE, { var = var })
  end
  if p.peek(state, ":") then
    local any = parse_any(state)
    -- variable 3
    return p.new_inner_node(NodeType.VARIABLE, { var = var, any = any })
  end
  local transform = parse_transform(state)
  p.expect(state, "}")
  -- variable 4
  return p.new_inner_node(NodeType.VARIABLE, { var = var, transform = transform })
end

-- Starts after int
local parse_tabstop_transform = function(state)
  if p.peek(state, "}") then
    -- tabstop 2
    return nil
  end
  local transform = parse_transform(state)
  p.expect(state, "}")
  -- tabstop 3
  return transform
end

parse_any = function(state)
  if p.peek(state, "$") then
    local got_bracket = p.peek(state, "{")
    local int = p.peek_pattern(state, "^%d+")
    if int ~= nil then
      if not got_bracket then
        -- tabstop 1
        return p.new_inner_node(NodeType.TABSTOP, { int = int })
      elseif p.peek(state, ":") then
        local any = parse_placeholder_any(state)
        return p.new_inner_node(NodeType.PLACEHOLDER, { int = int, any = any })
      elseif p.peek(state, "|") then
        local text = parse_choice_text(state)
        return p.new_inner_node(NodeType.CHOICE, { int = int, text = text })
      else
        local transform = parse_tabstop_transform(state)
        -- transform may be nil
        return p.new_inner_node(NodeType.TABSTOP, { int = int, transform = transform })
      end
    else
      return M.parse_variable(state, got_bracket)
    end
    p.raise_parse_error(state, "[any node]: expected int after '${' characters")
  else
    state.cur_parser = "text"
    local prev_input = state.input
    local text = parse_text(state)
    if state.input == prev_input then
      p.raise_parse_error(state, "unescaped char")
    else
      return p.new_inner_node(NodeType.TEXT, { text = text })
    end
  end
end

M.parse = function(input)
  local state = {
    input = input,
    source = input,
  }
  local ast = {}
  while state.input ~= "" do
    local prev_input = state.input
    local ok, result = pcall(parse_any, state)
    if ok then
      ast[#ast + 1] = result
    else
      ast = p.backtrack(ast, state, prev_input)
    end
  end
  return ast
end

return M

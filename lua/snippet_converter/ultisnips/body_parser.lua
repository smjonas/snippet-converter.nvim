local p = require("snippet_converter.base.parser_utils")
local NodeType = require("snippet_converter.base.node_type")

-- TODO: visual_tabstop

-- Grammar in EBNF:
-- any         ::= tabstop | placeholder | choice | code | text
-- tabstop     ::= '$' int
--                 | '${' int '}'
--                 [[ | '${' int  transform '}' ]]
-- placeholder ::= '${' int ':' any '}'
-- choice      ::= '${' int '|' text (',' text)* '|}'
-- code        ::= '`' text '`'
--                 | '`!p ' text '`'
--                 | '`!v `' text '`'
-- transform   ::= '/' regex '/' (format | text)+ '/' options
-- format      ::= '$' int | '${' int '}'
--                 | '${' int ':' '/upcase' | '/downcase' | '/capitalize' | '/camelcase' | '/pascalcase' '}'
--                 | '${' int ':+' if '}'
--                 | '${' int ':?' if ':' else '}'
--                 | '${' int ':-' else '}' | '${' int ':' else '}'
-- regex       ::= JavaScript Regular Expression value (ctor-string)
-- options     ::= JavaScript Regular Expression option (ctor-options)
-- var         ::= [_a-zA-Z] [_a-zA-Z0-9]*
-- int         ::= [0-9]+
-- text        ::= .*

local var_pattern = "[_a-zA-Z][_a-zA-Z0-9]*"
local options_pattern = "[^}]*"
local parse_int = p.pattern("[0-9]+")

local parse_text = function(state)
  -- '`', '{', '$' and '\' must be escaped; '}' signals the end of the text
  return p.parse_escaped_text(state, "[`{%$\\}]")
end

-- TODO
local parse_if = parse_text
local parse_else = parse_text

local parse_escaped_choice_text = function(state)
  return p.parse_escaped_text(state, "[%$}\\,|]")
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
      format_modifier = p.parse_format_modifier(state)
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
    return parse_text(state)
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
  return { regex = regex, format_or_text = format_or_text, options = options }
end

local parse_any
local parse_placeholder_any = function(state)
  state.cur_parser = "parse_placeholder_any"
  local any = parse_any(state)
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

local parse_code = function(state)
  local node_type
  if p.peek(state, "!p ") then
    node_type = NodeType.PYTHON_CODE
  elseif p.peek(state, "!v ") then
    node_type = NodeType.VIMSCRIPT_CODE
  elseif p.peek(state, "`") then
    node_type = NodeType.SHELL_CODE
  end
  local code = p.parse_escaped_text(state, "[`]")
  p.expect(state, "`")
  return p.new_inner_node(node_type, { code = code })
end

-- Starts after the int
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
      return p.parse_variable(state, got_bracket)
    end
  elseif p.peek(state, "`") then
    return parse_code(state)
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

local parser = {}

parser.parse = function(input)
  local state = {
    input = input,
  }
  local ast = {}
  while state.input ~= nil and state.input ~= "" do
    ast[#ast + 1] = parse_any(state)
  end
  return ast
end

return parser

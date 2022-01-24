local p = require("snippet_converter.base.parser_utils")
local NodeType = require("snippet_converter.base.node_type")

-- TODO: visual_tabstop

-- Grammar in EBNF:
-- any         ::= tabstop | placeholder | choice | code | text
-- tabstop     ::= '$' int
--                 | '${' int '}'
--                 | '${' int  transform '}'
-- placeholder ::= '${' int ':' any '}'
-- choice      ::= '${' int '|' text (',' text)* '|}'
-- code        ::= '`' text '`'
--                 | '`!p ' text '`'
--                 | '`!v `' text '`'
-- transform   ::= '/' regex '/' replacement '/' options
-- regex       ::= JavaScript Regular Expression value (ctor-string)
-- replacement ::= text
-- options     ::= text
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

local parse_regex = function(state)
  return p.parse_escaped_text(state, "[/]")
end

local parse_replacement = function(state)
  return p.parse_escaped_text(state, "[/]")
end

local parse_transform = function(state)
  p.expect(state, "/")
  local regex = parse_regex(state)
  p.expect(state, "/")
  local replacement = parse_replacement(state)
  p.expect(state, "/")
  local options = p.parse_pattern(state, options_pattern)
  return p.new_inner_node(
    NodeType.TRANSFORM,
    { regex = regex, replacement = replacement, options = options }
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

-- Starts after "`"
local parse_code = function(state)
  local node_type
  if p.peek(state, "!p ") then
    node_type = NodeType.PYTHON_CODE
  elseif p.peek(state, "!v ") then
    node_type = NodeType.VIMSCRIPT_CODE
  else
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
    end
    p.raise_parse_error(state, "[any node]: expected int after '${' characters")
  elseif p.peek(state, "`") then
    return parse_code(state)
  else
    local prev_input = state.input
    local text = parse_text(state)
    if state.input == prev_input then
      state.input = ""
    else
      return p.new_inner_node(NodeType.TEXT, { text = text })
    end
  end
end

local parser = {}

-- TODO: extract common code
parser.parse = function(input)
  local state = {
    input = input,
    source = input,
  }
  local ast = {}
  while state.input ~= nil and state.input ~= "" do
    ast[#ast + 1] = parse_any(state)
  end
  return ast
end

return parser

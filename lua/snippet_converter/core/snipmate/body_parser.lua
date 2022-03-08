local p = require("snippet_converter.core.parser_utils")
local NodeType = require("snippet_converter.core.node_type")

-- Grammar in EBNF:

-- any                ::= tabstop | placeholder | visual_placeholder | code | text
-- tabstop            ::= '$' int
--                        | '${' int '}'
--                        | '${' int  transform '}'
-- placeholder        ::= '${' int ':' any '}'
-- visual_placeholder ::= '${VISUAL}'
--                        | '${VISUAL:' text '}'
--                        | '${VISUAL:' text '/' search '/' replacement '/' options '}'
-- code               ::= '`' text '`'
-- transform          ::= '/' regex '/' replacement '/' options
-- regex              ::= JavaScript Regular Expression value (ctor-string)
-- search             ::= text
-- replacement        ::= text
-- options            ::= text
-- int                ::= [0-9]+
-- text               ::= .*

local options_pattern = "[^}]*"
local parse_text = function(state)
  return p.parse_escaped_text(state, ".", "[`${}\\]")
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

-- Starts after "`"
local parse_code = function(state)
  local code = p.parse_escaped_text(state, "[`]")
  p.expect(state, "`")
  return p.new_inner_node(NodeType.VIMSCRIPT_CODE, { code = code })
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
  print("CALLED WITH", vim.inspect(state))
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
      else
        local transform = parse_tabstop_transform(state)
        -- transform may be nil
        return p.new_inner_node(NodeType.TABSTOP, { int = int, transform = transform })
      end
    elseif p.peek(state, "VISUAL") then
      if p.peek(state, "}") then
        -- visual placeholder 1
        return p.new_inner_node(NodeType.VISUAL_PLACEHOLDER, {})
      elseif p.peek(state, ":") then
        local default_text = p.parse_escaped_text(state, "[/}]")
        if p.peek(state, "}") then
          -- visual placeholder 2
          return p.new_inner_node(NodeType.VISUAL_PLACEHOLDER, { default_text = default_text })
        end
        -- TODO: visual placeholder 3
      end
    end
    p.raise_backtrack_error(state, "[any node]: expected int after '${' characters")
  elseif p.peek(state, "`") then
    return parse_code(state)
  else
    local prev_input = state.input
    local text = parse_text(state)
    -- This happens if parse_text could not parse anything because the next char was not escaped.
    if state.input == prev_input then
      p.raise_backtrack_error(state, "unescaped char")
    else
      return p.new_inner_node(NodeType.TEXT, { text = text })
    end
  end
end

local parser = {}

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

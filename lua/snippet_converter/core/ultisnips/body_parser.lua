local p = require("snippet_converter.core.parser_utils")
local NodeType = require("snippet_converter.core.node_type")

-- Grammar in EBNF:
-- any                ::= tabstop | placeholder | visual_placeholder | choice | code | text
-- tabstop            ::= '$' int
--                        | '${' int '}'
--                        | '${' int  transform '}'
-- placeholder        ::= '${' int ':' any '}'
-- visual_placeholder ::= '${VISUAL}'
--                        | '${VISUAL:' text '}'
--                        | '${VISUAL:' text '/' search '/' replacement '/' options '}'
-- choice             ::= '${' int '|' text (',' text)* '|}'
-- code               ::= '`' text '`'
--                        | '`!p ' text '`'
--                        | '`!v `' text '`'
-- transform          ::= '/' regex '/' replacement '/' options
-- regex              ::= JavaScript Regular Expression value (ctor-string)
-- search             ::= text
-- replacement        ::= text
-- options            ::= text
-- int                ::= [0-9]+
-- text               ::= .*

local parser = {}

local options_pattern = "[^}]*"
local parse_text = function(state)
  -- '`', '{', '$' and '\' must be escaped; '}' signals the end of the text
  return p.parse_escaped_text(state, "[`{%$\\}]")
end

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
  return p.new_inner_node(NodeType.TRANSFORM, {
    regex = regex,
    regex_kind = NodeType.RegexKind.PYTHON,
    replacement = replacement,
    options = options,
  })
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

local parse_any = function(state)
  if p.peek(state, "$") then
    local got_bracket = p.peek(state, "{")
    local int = p.peek_pattern(state, "^%d+")
    if int ~= nil then
      if not got_bracket then
        -- tabstop 1
        return p.new_inner_node(NodeType.TABSTOP, { int = int })
      elseif p.peek(state, ":") then
        local any = p.parse_placeholder_any(state, parser.parse)
        return p.new_inner_node(NodeType.PLACEHOLDER, { int = int, any = any })
      elseif p.peek(state, "|") then
        if int == "0" then
          p.raise_parse_error(state, "choice node placeholder must not be 0")
        end
        local text = parse_choice_text(state)
        return p.new_inner_node(NodeType.CHOICE, { int = int, text = text })
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
          return p.new_inner_node(NodeType.VISUAL_PLACEHOLDER, { text = default_text })
        end
        -- TODO: visual placeholder 3
      end
    end
    p.raise_backtrack_error("[any node]: expected int after '${' characters")
  elseif p.peek(state, "`") then
    return parse_code(state)
  else
    local prev_input = state.input
    local text = parse_text(state)
    -- This happens if parse_text could not parse anything because the next char was not escaped.
    if state.input == prev_input then
      p.raise_backtrack_error("unescaped char")
    else
      return p.new_inner_node(NodeType.TEXT, { text = text })
    end
  end
end

---@param input string
---@return boolean success
---@return table | string
parser.parse = function(input)
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
    elseif result:match("^BACKTRACK") then
      ast = p.backtrack(state, ast, prev_input, parse_any)
    else
      -- A parser error occurred that is not a backtrack signal
      return false, result
    end
  end
  return true, ast
end

return parser

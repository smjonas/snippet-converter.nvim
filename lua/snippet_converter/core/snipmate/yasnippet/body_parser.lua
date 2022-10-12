local p = require("snippet_converter.core.parser_utils")
local NodeType = require("snippet_converter.core.node_type")

-- Grammar for YASnippet in EBNF

-- any                ::= tabstop | placeholder | code | text
-- tabstop            ::= '$' int
--                        | '${' int ':' transform '}'
--                        | '${' int ':$' transform '}'
-- placeholder        ::= '${' int ':' any '}'
-- transform          ::= '$(' replacement ')'
-- replacement        ::= text
-- int                ::= [0-9]+
-- code               ::= '`' text '`'
-- text               ::= .*

local parser = {}

local parse_text = function(state)
  return p.parse_escaped_text(state, ".", "[`${}\\]")
end

local parse_transform = function(state)
  p.expect(state, "(")
  local text = p.parse_escaped_text(state, "[%)]", "[%)]")
  p.expect(state, ")")
  return p.new_inner_node(NodeType.TRANSFORM, { replacement = text })
end

-- Starts after "`"
local parse_code = function(state)
  local code = p.parse_escaped_text(state, "[`]")
  p.expect(state, "`")
  return p.new_inner_node(NodeType.EMACS_LISP_CODE, { code = code })
end

local parse_any = function(state)
  if p.peek(state, "$") then
    local got_bracket = p.peek(state, "{")
    local int = p.peek_pattern(state, "^%d+")
    if int ~= nil then
      if not got_bracket then
        -- tabstop
        return p.new_inner_node(NodeType.TABSTOP, { int = int })
      elseif p.peek(state, ":$") then
        -- tabstop 2 / 3
        -- Skip a potential second dollar sign
        p.peek(state, "$")
        local transform = parse_transform(state)
        p.expect(state, "}")
        return p.new_inner_node(NodeType.TABSTOP, { int = int, transform = transform })
      elseif p.peek(state, ":") then
        -- placeholder 1
        local any = p.parse_placeholder_any(state, function(input)
          -- The snipmate body parser will always succeed, but parse_placeholder_any
          -- expects a function returning a boolean and a string
          return true, parser.parse(input)
        end)
        return p.new_inner_node(NodeType.PLACEHOLDER, { int = int, any = any })
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
    else
      ast = p.backtrack(state, ast, prev_input, parse_any)
    end
  end
  return ast
end

return parser

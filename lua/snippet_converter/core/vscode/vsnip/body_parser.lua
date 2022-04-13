local VSCodeParser = require("snippet_converter.core.vscode.body_parser")
local p = require("snippet_converter.core.parser_utils")
local NodeType = require("snippet_converter.core.node_type")

-- Grammar in EBNF (a superset of VSCodes grammar: https://code.visualstudio.com/docs/editor/userdefinedsnippets#_grammar)
-- any                ::= tabstop | placeholder | choice | code | variable | text
-- tabstop            ::= '$' int
--                        | '${' int '}'
--                        | '${' int  transform '}'
-- placeholder        ::= '${' int ':' any '}'
-- choice             ::= '${' int '|' text (',' text)* '|}'
-- code               ::= '${VIM:' text '}'
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

---@class VSnipParser : VSCodeParser
local VSnipParser = VSCodeParser:new {
  Variable = setmetatable(VSCodeParser.Variable, { __index = { VIM = "VIM" } }),
}
VSnipParser.variable_tokens = { table.unpack(VSCodeParser.variable_tokens) }
table.insert(VSnipParser.variable_tokens, "VIM")

local var_pattern = "[_a-zA-Z][_a-zA-Z0-9]*"

function VSnipParser:parse_variable(got_bracket)
  local var = self:parse_pattern(var_pattern)
  if not vim.tbl_contains(VSnipParser.variable_tokens, var) then
    self:raise_parse_error("parse_variable: invalid token" .. var)
  end
  if not got_bracket or self:peek("}") then
    if var == VSnipParser.Variable.VIM then
      self:raise_parse_error("empty code in vimscript node")
    end
    -- variable 1 / 2
    return p.new_inner_node(NodeType.VARIABLE, { var = var })
  end
  if self:peek(":") then
    if var == VSnipParser.Variable.VIM then
      -- Return a vimscript node, so target converters that support vimscript interpolation
      -- can handle it correctly
      local code = self:parse_escaped_text("[\\]", "[}]")
      self:expect("}")
      return p.new_inner_node(NodeType.VIMSCRIPT_CODE, { code = code })
    end
    local any = self:parse_any()
    -- variable 3
    self:expect("}")
    return p.new_inner_node(NodeType.VARIABLE, { var = var, any = any })
  end
  self:raise_parse_error("transform in variable node is not supported by vim-vsnip")
end

function VSnipParser:raise_parse_error(description)
  -- Only show the line where the error occurred.
  local error_line = self.input:match("^[^\n]*")
  local source_line = self.source:match("^[^\n]*")
  if #source_line < #self.source then
    source_line = source_line .. "..."
  end
  error(("%s at '%s' (input line: '%s')"):format(description, error_line, source_line), 0)
end

---@param input string
---@return boolean success
---@return table | string
function VSnipParser:parse(input)
  self.input = input
  self.source = input
  local ast = {}
  while self.input ~= "" do
    local prev_input = self.input
    local ok, result = pcall(VSCodeParser.parse_any, self)
    if ok then
      ast[#ast + 1] = result
    elseif result:match("^BACKTRACK") then
      ast = self:backtrack(ast, prev_input)
    else
      return false, result
    end
  end
  return true, ast
end

return VSnipParser

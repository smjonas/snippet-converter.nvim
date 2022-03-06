local vscode_parser = require("snippet_converter.core.vscode.body_parser")
local p = require("snippet_converter.core.parser_utils")
local NodeType = require("snippet_converter.core.node_type")

-- Grammar in EBNF (a superset of VSCodes grammar: https://code.visualstudio.com/docs/editor/userdefinedsnippets#_grammar)
-- any                ::= tabstop | placeholder | choice | code | variable | text
-- tabstop            ::= '$' int
--                        | '${' int '}'
--                        | '${' int  transform '}'
-- placeholder        ::= '${' int ':' any '}'
-- choice             ::= '${' int '|' text (',' text)* '|}'
-- TODO: check whether '$VIM' is parsed
-- code               ::= '$VIM' | '${VIM}'
--                        | '${VIM:' any '}'
--                        | '${VIM' transform '}'
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

local M = setmetatable({}, vscode_parser)

local Variable = vscode_parser.Variable
Variable.VIM = "VIM"
local variable_tokens = vscode_parser.variable_tokens
variable_tokens[#variable_tokens + 1] = "VIM"

M.parse_variable = function(state, got_bracket, _)
  return vscode_parser.parse_variable(state, got_bracket, variable_tokens)
end

return M

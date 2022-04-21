local NodeType = require("snippet_converter.core.node_type")
local p = require("snippet_converter.core.parser_utils")

---@class VSCodeParser : ParserUtils
local VSCodeParser = setmetatable({}, { __index = p })

-- Enable inheritance
function VSCodeParser:new(o)
  o = o or {}
  setmetatable(o, { __index = self })
  return o
end

-- Grammar in EBNF (see https://code.visualstudio.com/docs/editor/userdefinedsnippets#_grammar)
-- any                ::= tabstop | placeholder | choice | variable | text
-- tabstop            ::= '$' int
--                        | '${' int '}'
--                        | '${' int transform '}'
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
-- replacement        ::= (format | text)+
-- options            ::= text
-- var                ::= [_a-zA-Z] [_a-zA-Z0-9]*
-- int                ::= [0-9]+
-- text               ::= .*

VSCodeParser.Variable = {
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
VSCodeParser.variable_tokens = vim.tbl_values(VSCodeParser.Variable)

local format_modifier_tokens = {
  "upcase",
  "downcase",
  "capitalize",
  "camelcase",
  "pascalcase",
}

local var_pattern = "[_a-zA-Z][_a-zA-Z0-9]*"
local options_pattern = "[^}]*"
local parse_int = p.pattern("[0-9]+")

-- Expose to subclasses.
function VSCodeParser:parse_text()
  -- '$' and '}' must be escaped
  return self:parse_escaped_text("[$}]")
end

-- TODO
VSCodeParser.parse_if = VSCodeParser.parse_text
VSCodeParser.parse_else = VSCodeParser.parse_text

function VSCodeParser:parse_escaped_choice_text()
  return self:parse_escaped_text("[%$}\\,|]")
end

-- Parses a JavaScript regex
function VSCodeParser:parse_regex()
  return self:parse_escaped_text("[/]")
end

function VSCodeParser:parse_format_modifier()
  local format_modifier = self:parse_pattern("[a-z]+")
  if not vim.tbl_contains(format_modifier_tokens, format_modifier) then
    error("parse_format_modifier: invalid modifier " .. format_modifier)
  end
  return format_modifier
end

-- Starts at the second cha
function VSCodeParser:parse_format()
  local int_only, int = self:parse_bracketed(parse_int)
  if int_only then
    -- format 1 / 2
    return p.new_inner_node(NodeType.FORMAT, { int = int })
  else
    local format_modifier, _if, _else
    if self:peek(":/") then
      -- format 3
      format_modifier = self:parse_format_modifier()
    else
      if self:peek(":+") then
        -- format 4
        _if = self:parse_if()
      elseif self:peek(":?") then
        -- format 5
        _if = self:parse_if()
        self:expect(":")
        _else = self:parse_else()
      elseif self:peek(":") then
        -- format 6 / 7
        self:peek("-")
        _else = self:parse_else()
      end
    end
    self:expect("}")
    return p.new_inner_node(NodeType.FORMAT, {
      int = int,
      format_modifier = format_modifier,
      _if = _if,
      _else = _else,
    })
  end
end

function VSCodeParser:parse_replacement()
  if self:peek("$") then
    return self:parse_format()
  else
    return p.new_inner_node(NodeType.TEXT, { text = self:parse_escaped_text("[%$}]", "/") })
  end
end

-- Expose to subclasses
function VSCodeParser:parse_transform()
  self:expect("/")
  local regex = self:parse_regex()
  self:expect("/")
  local replacement = { self:parse_replacement() }
  while not self:peek("/") do
    replacement[#replacement + 1] = self:parse_replacement()
  end
  local options = self:parse_pattern(options_pattern)
  return p.new_inner_node(NodeType.TRANSFORM, {
    regex = regex,
    regex_kind = NodeType.RegexKind.JAVASCRIPT,
    replacement = replacement,
    options = options,
  })
end

function VSCodeParser:parse_placeholder_any()
  local any = { self:parse_any() }
  local pos = 2
  while self.input:sub(1, 1) ~= "}" do
    any[pos] = self:parse_any()
    pos = pos + 1
  end
  self:expect("}")
  return any
end

function VSCodeParser:parse_choice_text()
  local text = { self:parse_escaped_choice_text() }
  while self:peek(",") do
    text[#text + 1] = self:parse_escaped_choice_text()
  end
  self:expect("|}")
  return text
end

-- Starts at char after '$', or after '{' if got_bracket is true
function VSCodeParser:parse_variable(got_bracket)
  local var = self:parse_pattern(var_pattern)
  if not vim.tbl_contains(VSCodeParser.variable_tokens, var) then
    error("parse_variable: invalid token " .. var)
  end
  if not got_bracket or self:peek("}") then
    -- variable 1 / 2
    return p.new_inner_node(NodeType.VARIABLE, { var = var })
  end
  if self:peek(":") then
    local any = self:parse_any()
    -- variable 3
    return p.new_inner_node(NodeType.VARIABLE, { var = var, any = any })
  end
  local transform = self:parse_transform()
  self:expect("}")
  -- variable 4
  return p.new_inner_node(NodeType.VARIABLE, { var = var, transform = transform })
end

-- Starts after int
function VSCodeParser:parse_tabstop_transform()
  if self:peek("}") then
    -- tabstop 2
    return nil
  end
  local transform = self:parse_transform()
  self:expect("}")
  -- tabstop 3
  return transform
end

function VSCodeParser:parse_any()
  if self:peek("$") then
    local got_bracket = self:peek("{")
    local int = self:peek_pattern("^%d+")
    if int ~= nil then
      if not got_bracket then
        -- tabstop 1
        return p.new_inner_node(NodeType.TABSTOP, { int = int })
      elseif self:peek(":") then
        local any = self:parse_placeholder_any()
        return p.new_inner_node(NodeType.PLACEHOLDER, { int = int, any = any })
      elseif self:peek("|") then
        local text = self:parse_choice_text()
        return p.new_inner_node(NodeType.CHOICE, { int = int, text = text })
      else
        local transform = self:parse_tabstop_transform()
        -- transform may be nil
        return p.new_inner_node(NodeType.TABSTOP, { int = int, transform = transform })
      end
    else
      return self:parse_variable(got_bracket)
    end
  else
    self.cur_parser = "text"
    local prev_input = self.input
    local text = self:parse_text()
    if self.input == prev_input then
      p.raise_backtrack_error("unescaped char")
    else
      return p.new_inner_node(NodeType.TEXT, { text = text })
    end
  end
end

function VSCodeParser:parse(input)
  self.input = input
  self.source = input
  local ast = {}
  while self.input ~= "" do
    local prev_input = self.input
    local ok, result = pcall(VSCodeParser.parse_any, self)
    if ok then
      ast[#ast + 1] = result
    else
      ast = self:backtrack(ast, prev_input, self.parse_any)
    end
  end
  return ast
end

return VSCodeParser

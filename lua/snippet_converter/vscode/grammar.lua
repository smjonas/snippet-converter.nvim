local grammar = {}

local primitives = require("snippet_converter.base.parser.primitives")

-- As supported by VSCode,
-- see https://code.visualstudio.com/docs/editor/userdefinedsnippets#_variables
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

local either = primitives.either
local all = primitives.all
local at_least = primitives.at_least

local var = primitives.pattern("[_a-zA-Z][_a-zA-Z0-9]*")
local int = primitives.pattern("%d+")
local text = primitives.pattern(".*")

local patterns = {
 "$", "{", "}", "${", ":", ":?", ":-", "/", ",", "|", "|}",
 "/normcase", "/downcase", "/capitalize", "/camelcase", "/pascalcase"
}

-- Patterns
local p = {}
for _, pattern in ipairs(patterns) do
  p[pattern] = primitives.pattern(pattern)
end

local tabstop = either {
  all{ p["$"], int, },
  all{ p["${"], int, p["}"], },
  all{ p["${"], int, transform, p["}"], }
}

local any
local placeholder = all {
  p["${"], int, p[":"], any, p["}"],
}

local choice = all {
  p["${"], int, p["|"], text,
  at_least(0, all{ p[","], text }), p["|}"],
}

local variable = either {
  all { p["$"], var, },
  all { p["${"], var, p["}"] },
  all { p["$"], var, }
}

any = either {
  tabstop, placeholder, choice, variable, text,
}

local format = either {
  all { p["$"], int },
  all { p["${"], int, p["}"] },
  all { p["${"], int, p[":"], either {
    p["/upcase"], p["/downcase"], p["/capitalize"], p["/camelcase"], p["/pascalcase"], p["}"],
    -- TODO: handle :+ if else etc
    -- all { p["+"],  }
    }
  },
}

local options = text
local regex = text

local transform = all {
  p["/"], at_least(1, either { format, text }), p["/"], options
}

local number

return grammar

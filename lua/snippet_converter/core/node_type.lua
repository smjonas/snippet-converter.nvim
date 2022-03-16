local NodeType = {
  -- General
  TABSTOP = 1,
  PLACEHOLDER = 2,
  CHOICE = 3,
  TEXT = 4,
  TRANSFORM = 5,
  FORMAT = 6,
  -- VSCode
  VARIABLE = 7,
  -- UltiSnips
  VISUAL_PLACEHOLDER = 8,
  PYTHON_CODE = 9,
  SHELL_CODE = 10,
  -- UltiSnips / SnipMate / vsnip
  VIMSCRIPT_CODE = 11,
}

local _to_string = {
  "tabstop",
  "placeholder",
  "choice",
  "text",
  "transform",
  "format",
  "variable",
  "visual placeholder",
  "Python code",
  "shell code",
  "Vimscript code",
}

NodeType.to_string = function(type)
  return _to_string[type]
end

-- Used to differentiate between transform nodes with regex attributes
NodeType.RegexKind = {
  JAVASCRIPT = 1,
  PYTHON = 2,
}

local _regex_kind_to_string = {
  "JavaScript",
  "Python",
}

NodeType.RegexKind.to_string = function(kind)
  return _regex_kind_to_string[kind]
end

return NodeType

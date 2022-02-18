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
  "python code",
  "shell code",
  "vimscript code",
}

NodeType.to_string = function(type)
  return _to_string[type]
end

return NodeType

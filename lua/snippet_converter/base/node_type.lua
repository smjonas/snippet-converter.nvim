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
  PYTHON_CODE = 8,
  SHELL_CODE = 9,
  -- UltiSnips / vsnip
  VIMSCRIPT_CODE = 10,
}

local _to_string = {
  "TABSTOP",
  "PLACEHOLDER",
  "CHOICE",
  "TEXT",
  "TRANSFORM",
  "FORMAT",
  "VARIABLE",
  "PYTHON_CODE",
  "SHELL_CODE",
  "VIMSCRIPT_CODE",
}

NodeType.to_string = function(type)
  return _to_string[type]
end

return NodeType

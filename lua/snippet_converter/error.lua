local M = {}

local Type = {
  PARSER_ERROR = "1",
  CONVERTER_ERROR = "2",
}
M.Type = Type

M.new_parser_error = function(line_nr, msg)
  error(Type.PARSER_ERROR .. msg)
end

M.raise_converter_error = function(node)
  error(("%sconversion of %s is not supported"):format(Type.CONVERTER_ERROR, node), 0)
end

return M

local M = {}

local Type = {
  PARSER_ERROR = "1",
  CONVERTER_ERROR = "2",
}
M.Type = Type

M.assert_all = function(assertions, errors_ptr)
  for _, assertion in ipairs(assertions) do
    if not assertion.predicate then
      errors_ptr[#errors_ptr + 1] = assertion.msg()
      return false
    end
  end
  return true
end

M.raise_converter_error = function(node_string)
  error(("conversion of %s is not supported"):format(node_string), 0)
end

M.new_parser_error = function(path, line_nr, msg)
  return {
    path = path,
    line_nr = line_nr,
    msg = msg,
  }
end

return M

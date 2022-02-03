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

M.raise_converter_error = function(node)
  error(("%sconversion of %s is not supported"):format(Type.CONVERTER_ERROR, node), 0)
end

return M

local vscode_parser = require("snippet_converter.core.vscode.parser")
local err = require("snippet_converter.utils.error")

local M = setmetatable({}, { __index = vscode_parser })

M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr)
  return vscode_parser.parse(path, parsed_snippets_ptr, parser_errors_ptr, { self = M })
end

M.verify_snippet_format = function(snippet_name, snippet_info, errors_ptr)
  local ok = vscode_parser.verify_snippet_format(snippet_name, snippet_info, errors_ptr)
  if not ok then
    return false
  end
  local got_luasnips_key = type(snippet_info.luasnip) == "table"
  local autotrigger = got_luasnips_key and snippet_info.luasnip.autotrigger
  local assertions = {
    {
      predicate = got_luasnips_key,
      msg = function()
        return "luasnip must be a table, got " .. type(snippet_info.luasnip)
      end,
    },
    {
      predicate = (not got_luasnips_key and true) or type(autotrigger) == "boolean",
      msg = function()
        return "luasnip.autotrigger must be a boolean, got " .. type(snippet_name)
      end,
    },
  }
  return err.assert_all(assertions, errors_ptr)
end

return M

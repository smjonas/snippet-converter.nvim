local header_parser = require("snippet_converter.core.ultisnips.header_parser")
local body_parser = require("snippet_converter.core.ultisnips.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.get_lines = function(path)
  return io.read_file(path)
end

-- TODO: docs for return values and params
M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr, context_ptr)
  local lines = M.get_lines(path)
  local cur_snippet
  local found_snippet_header = false

  local found_global_python_code = false
  local cur_global_code = {}
  local cur_priority
  local cur_context

  local start_pos = #parsed_snippets_ptr + 1
  local pos = start_pos

  for line_nr, line in ipairs(lines) do
    if not found_snippet_header then
      local header = M.parse_header(line)
      if header then
        cur_snippet = header
        cur_snippet.path = path
        cur_snippet.line_nr = line_nr
        cur_snippet.body = {}
        found_snippet_header = true
      elseif line:match("^context") then
        local context = line:match([[^context "(.+)"]])
        if context then
          cur_context = context
        else
          parser_errors_ptr[#parser_errors_ptr + 1] = err.new_parser_error(
            path,
            line_nr,
            ([[missing context body "%s"]]):format(line)
          )
        end
      elseif line:match("^global !p") then
        found_global_python_code = true
      elseif line:match("^endglobal") then
        table.insert(context_ptr.global_code, cur_global_code)
        cur_global_code = {}
        found_global_python_code = false
      elseif found_global_python_code then
        table.insert(cur_global_code, line)
      else
        local priority = line:match("^priority (-?%d+)")
        if priority then
          cur_priority = priority
        elseif line:match("^priority") then
          parser_errors_ptr[#parser_errors_ptr + 1] = err.new_parser_error(
            path,
            line_nr,
            ([[invalid priority "%s"]]):format(line)
          )
        end
      end
      -- TODO: handle pre_expand, post_expand:
      -- https://github.com/SirVer/ultisnips/blob/e96733b5db27b48943db86dd8623f1497b860bc6/test/test_ParseSnippets.py#L329
    elseif line:match("^endsnippet") then
      local ok, result = pcall(body_parser.parse, table.concat(cur_snippet.body, "\n"))
      if ok then
        -- TODO: refactor
        if cur_priority then
          cur_snippet.priority = cur_priority
          cur_priority = nil
        end
        if cur_context then
          print(cur_context)
          cur_snippet.custom_context = cur_context
          cur_context = nil
        end
        cur_snippet.body = result
        parsed_snippets_ptr[pos] = cur_snippet
        pos = pos + 1
      else
        local start_line_nr = line_nr - #cur_snippet.body
        parser_errors_ptr[#parser_errors_ptr + 1] = err.new_parser_error(
          path,
          start_line_nr,
          result
        )
      end
      found_snippet_header = false
    else
      table.insert(cur_snippet.body, line)
    end
  end
  return pos - 1
end

M.parse_header = function(line)
  local stripped_header = line:match("^%s*snippet%s+(.-)%s*$")
  if stripped_header ~= nil then
    local header = header_parser.parse(stripped_header)
    return not vim.tbl_isempty(header) and header
  end
end

return M

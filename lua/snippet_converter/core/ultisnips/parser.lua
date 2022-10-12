local header_parser = require("snippet_converter.core.ultisnips.header_parser")
local body_parser = require("snippet_converter.core.ultisnips.body_parser")
local io = require("snippet_converter.utils.io")
local err = require("snippet_converter.utils.error")

local M = {}

M.get_lines = function(path)
  return io.read_file(path)
end

---@param path string the path to the snippet file used by get_lines
---@param parsed_snippets_ptr table contains all previously parsed snippets, any new snippets will be added to the end of it
---@param parser_errors_ptr table contains all previously encountered errors, any new errors that occur during parsing will be added to the end of it
---@param opts table? opts.context contains all previously gathered global context, any global Python code found in the input file will be appended to the opts.context.global_code subtable; if opts.lines is specified, get_lines will not be called
---@return number the new number of snippets that have been parsed
M.parse = function(path, parsed_snippets_ptr, parser_errors_ptr, opts)
  opts = opts or {}
  local lines = opts.lines or M.get_lines(path)
  local cur_snippet
  local found_snippet_header = false

  local found_global_python_code = false
  local cur_global_code = {}
  local cur_extends
  local cur_priority
  local cur_context

  local start_pos = #parsed_snippets_ptr + 1
  local pos = start_pos

  for line_nr, line in ipairs(lines) do
    if not found_snippet_header then
      local header = M.parse_header(path, line, line_nr, parser_errors_ptr)
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
          parser_errors_ptr[#parser_errors_ptr + 1] =
            err.new_parser_error(path, line_nr, ([[invalid context "%s"]]):format(line))
        end
      elseif line:match("^global !p") then
        found_global_python_code = true
      elseif line:match("^endglobal") then
        table.insert(opts.context.global_code, cur_global_code)
        cur_global_code = {}
        found_global_python_code = false
      elseif found_global_python_code then
        table.insert(cur_global_code, line)
      elseif line:match("^extends") then
        local fts = line:match("^extends (.+)")
        if fts then
          cur_extends = fts
        end
      else
        local priority = line:match("^priority (%-?%d+)")
        if priority then
          cur_priority = tonumber(priority)
        elseif line:match("^priority") then
          parser_errors_ptr[#parser_errors_ptr + 1] =
            err.new_parser_error(path, line_nr, ([[invalid priority "%s"]]):format(line))
        end
      end
      -- TODO: handle pre_expand, post_expand:
      -- https://github.com/SirVer/ultisnips/blob/e96733b5db27b48943db86dd8623f1497b860bc6/test/test_ParseSnippets.py#L329
    elseif line:match("^endsnippet$") then
      local ok, result
      -- Empty snippet body
      if #cur_snippet.body == 0 then
        ok, result = true, {}
      else
        -- For a snippet that consists of a single empty line the body would be "".
        -- Make sure to set the body to a newline character in that case.
        local single_empty_line = #cur_snippet.body == 1 and cur_snippet.body[1] == ""
        local body = single_empty_line and "\n" or table.concat(cur_snippet.body, "\n")
        ok, result = body_parser.parse(body)
      end
      if ok then
        -- TODO: refactor
        if cur_priority then
          cur_snippet.priority = cur_priority
          cur_priority = nil
        end
        if cur_context then
          cur_snippet.custom_context = cur_context
          cur_context = nil
        end
        cur_snippet.body = result
        parsed_snippets_ptr[pos] = cur_snippet
        pos = pos + 1
      else
        local start_line_nr = line_nr - #cur_snippet.body
        parser_errors_ptr[#parser_errors_ptr + 1] = err.new_parser_error(path, start_line_nr, result)
      end
      found_snippet_header = false
    else
      table.insert(cur_snippet.body, line)
    end
  end

  if cur_extends then
    for _, sub_ft in ipairs(vim.split(cur_extends, ",%s", { trim_empty = true })) do
      if not opts.context.langs_per_filetype[sub_ft] then
        opts.context.langs_per_filetype[sub_ft] = { sub_ft }
      end
      table.insert(opts.context.langs_per_filetype[sub_ft], opts.filetype)
    end
  end
  return pos - 1
end

M.parse_header = function(path, line, line_nr, parser_errors_ptr)
  local stripped_header = line:match("^%s*snippet%s+(.-)%s*$")
  if stripped_header then
    local ok, header = pcall(header_parser.parse, stripped_header)
    if not ok then
      parser_errors_ptr[#parser_errors_ptr + 1] = err.new_parser_error(path, line_nr, header)
      return nil
    end
    return header
  end
end

return M

local M = {}

-- Adapted from https://github.com/nvim-lua/nvim-package-specification/blob/master/lua/packspec/schema.lua
M.dedent = function(s)
  local lines = {}
  local indent

  for line in s:gmatch("[^\n]*\n?") do
    if not indent then
      if not line:match("^%s*$") then
        -- Save pattern for indentation from the first non-empty line
        indent, line = line:match("^(%s*)(.*)$")
        indent = "^" .. indent .. "(.*)$"
        table.insert(lines, line)
      end
    else
      if line:match("^%s*$") then
        -- Replace empty lines with a single newline character.
        -- Empty lines are handled separately to allow the
        -- closing "]]" to be one indentation level lower.
        table.insert(lines, "\n")
      else
        -- Strip indentation on non-empty lines
        line = line:match(indent)
        if not line then
          vim.notify("[snippet-converter.nvim] helper.dedent: inconsistent indentation", vim.log.levels.ERROR)
          return nil
        end
        table.insert(lines, line)
      end
    end
  end
  -- Trim trailing whitespace
  return table.concat(lines):match("^(.-)%s*$")
end

return M

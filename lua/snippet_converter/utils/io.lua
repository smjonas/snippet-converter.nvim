local M = {}

M.file_exists = function(path)
  return vim.fn.filereadable(vim.fn.expand(path)) == 1
end

M.read_file = function(path)
  -- Replace this with libuv's uv.read_file? However, in that case we only get the raw
  -- buffer content and would need to split the string it to get the lines.
  return vim.fn.readfile(vim.fn.expand(path))
end

M.write_file = function(object, path)
  local dir_name = path:match("(.*)(%..+)$")
  -- Create missing directories (if any)
  if vim.fn.isdirectory(dir_name) ~= 1 then
    -- TODO: check output filename out.snippets for vscode output
    vim.fn.mkdir(dir_name, "p")
  end
  vim.fn.writefile(object, path)
end

M.read_json = function(path)
  local lines = table.concat(M.read_file(path), "\n")
  return vim.json.decode(lines)
end

return M

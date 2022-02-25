local M = {}

local uv = vim.loop

M.file_exists = function(path, mode)
  return uv.fs_access(vim.fn.expand(path), mode or "R")
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
    vim.fn.mkdir(dir_name, "p")
  end
  vim.fn.writefile(object, path)
end

local _json_decode
-- Since NVIM v0.6.0
if vim.json then
  _json_decode = vim.json.decode
else
  _json_decode = vim.fn.json_decode
end

M.read_json = function(path)
  local lines = table.concat(M.read_file(path), "\n")
  return _json_decode(lines)
end

local _json_encode
if vim.json then
  _json_encode = vim.json.encode
else
  _json_encode = vim.fn.json_encode
end

M.json_encode = _json_encode

return M

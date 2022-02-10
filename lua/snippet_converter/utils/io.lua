local M = {}

M.file_exists = function(path)
  return vim.fn.filereadable(vim.fn.expand(path)) == 1
end

M.is_file = function(path)
  return vim.fn.fnamemodify(path, ":e") ~= nil or M.file_exists(path)
end

M.read_file = function(path)
  -- Replace this with an async implementation (libuv)?
  return vim.fn.readfile(path)
end

M.write_file = function(object, path)
  local dir_name = vim.fn.fnamemodify(path, ":p:h")
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

local utils = {}

utils.file_exists = function(path)
  return vim.fn.filereadable(vim.fn.expand(path)) == 1
end

utils.read_file = function(path)
  -- Maybe replace this with an async implementation?
  return vim.fn.readfile(path)
end

utils.write_file = function(object, path)
  vim.fn.writefile(object, path)
end

local _json_decode
-- Since NVIM v0.6.0
if vim.json then
  _json_decode = vim.json.decode
else
  _json_decode = vim.fn.json_decode
end

utils.read_json = function(path)
  local lines = table.concat(utils.read_file(path), "\n")
  return _json_decode(lines)
end

local _json_encode
if vim.json then
  _json_encode = vim.json.encode
else
  _json_encode = vim.fn.json_encode
end

utils.json_encode = _json_encode

return utils

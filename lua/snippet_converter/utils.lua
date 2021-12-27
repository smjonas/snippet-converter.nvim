local utils = {}

utils.file_exists = function(path)
  return vim.fn.filereadable(vim.fn.expand(path))
end

utils.read_file = function(path)
  -- Maybe replace this with an async implementation?
  return vim.fn.readfile(path)
end

local _json_decode
-- Since NVIM v0.6.0
if vim.json then
  _json_decode = vim.json.decode
else
  _json_decode = vim.fn.json_decode
end

utils.json_decode = function(path)
  local lines = vim.fn.join(utils.read_file(path), "\n")
  return _json_decode(lines)
end

return utils

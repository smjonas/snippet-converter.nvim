local utils = {}

utils.read_file = function(path)
  -- Maybe replace this with an async implementation?
  return vim.fn.readfile(path)
end

local json_decode
-- Since NVIM v0.6.0
if vim.json then
  json_decode = vim.json.decode
else
  json_decode = vim.fn.json_decode
end

utils.json_decode = json_decode

return utils

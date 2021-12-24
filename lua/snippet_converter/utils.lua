local utils = {}

utils.read_file = function(path)
  -- We might want to replace this with an async implementation
  return vim.fn.readfile(path)
end

return utils

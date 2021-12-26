local M = {}

function M.setup(config)
  require("snippet_converter.loader").load(config)
end

return M

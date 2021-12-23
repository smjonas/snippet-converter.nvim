local M = {}

function M.setup(config)
  P(config)
  require("snippet_converter.loaders").load(config.sources[1])
end

return M

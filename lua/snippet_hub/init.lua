local M = {}

function M.setup(config)
  P(config)
  require("snippet_hub.loaders").load(config.sources[1])
end

return M

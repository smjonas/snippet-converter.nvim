local M = {}

function M.setup(config)
  P(config)
  require("snippet_hub.loader").load(config.sources[1])
end

return M

---@class HeadlessView
local HeadlessView = {}

---@param model Model
function HeadlessView:draw(model)
  local num_converted_snippets = model.total_num_snippets - model.total_num_failures
  vim.notify(
    ("Converted %d / %d snippets"):format(num_converted_snippets, model.total_num_snippets)
  )
end

function HeadlessView:destroy()
  -- No-op
end

return HeadlessView

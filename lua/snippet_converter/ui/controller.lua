local View = require("snippet_converter.ui.view")

local Controller = {}

Controller.new = function()
  return setmetatable({}, { __index = Controller })
end

function Controller:create_view(model, settings)
  if self.view ~= nil then
    self.view:destroy()
  end
  self.model = model
  self.view = View.new(settings)
  self.view:open()
  self.view:draw(model, false)
end

function Controller:finalize()
  self.model.is_converting = false
  self.view:draw(self.model, false)
end

return Controller

local View = require("snippet_converter.ui.view")

local Controller = {}

Controller.new = function()
  return setmetatable({}, { __index = Controller })
end

function Controller:create_view(model, settings)
  print(2)
  if self.view ~= nil then
    self.view:destroy()
  end
  self.model = model
  self.view = View.new(settings)
  self.view:open()
  self.view:draw(model, false, true)
end

function Controller:finalize()
  self.view:draw(self.model, false, false)
end

return Controller

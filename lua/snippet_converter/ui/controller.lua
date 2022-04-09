local View = require("snippet_converter.ui.view")
local HeadlessView = require("snippet_converter.ui.headless_view")

---@class Controller
---@field view View | HeadlessView
---@field model Model
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
  self.view:draw(model, true)
end

function Controller:create_headless_view(model)
  self.model = model
  self.view = HeadlessView
end

function Controller:finalize()
  self.model.is_converting = false
  self.view:draw(self.model, true)
end

return Controller

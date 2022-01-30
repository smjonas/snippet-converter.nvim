local TaskState = require("snippet_converter.ui.task_state")
local view = require("snippet_converter.ui.view")
local snippet_engines = require("snippet_converter.snippet_engines")

local Controller = {}

Controller.new = function()
  return setmetatable({}, { __index = Controller })
end

function Controller:create_view(model)
  if self.view ~= nil then
    self.view:destroy()
  end
  self.model = model
  self.view = view:new()
  self.view:open()
end

function Controller:add_task(source_format, num_snippets, num_files)
  local tasks = self.model.tasks or {}
  tasks[#tasks + 1] = {
    state = TaskState.STARTED,
    source_format = snippet_engines[source_format].label,
    num_snippets = num_snippets,
    num_files = num_files,
  }
  self.model.tasks = tasks
  self.view:draw(self.model)
end

return Controller

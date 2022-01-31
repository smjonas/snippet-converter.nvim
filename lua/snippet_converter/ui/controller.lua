local snippet_engines = require("snippet_converter.snippet_engines")
local TaskState = require("snippet_converter.ui.task_state")
local view = require("snippet_converter.ui.view")

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

function Controller:notify_conversion_started(source_format, num_snippets, num_input_files)
  local tasks = self.model.tasks or {}
  tasks[snippet_engines[source_format].label] = {
    state = TaskState.CONVERSION_STARTED,
    num_snippets = num_snippets,
    num_input_files = num_input_files,
    failures = {},
  }
  self.model.tasks = tasks
  self.view:draw(self.model)
end

function Controller:notify_conversion_completed(source_format, target_format, failures)
  local tasks = self.model.tasks
  local label = snippet_engines[source_format].label
  tasks[label].failures[target_format] = failures
  tasks[label].state = TaskState.CONVERSION_COMPLETED
  self.model.tasks = tasks
  self.view:draw(self.model)
end

return Controller

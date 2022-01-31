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

function Controller:notify_conversion_started(source_format, num_snippets, num_files)
  print(1)
  local tasks = self.model.tasks or {}
  tasks[source_format] = {
    state = TaskState.STARTED,
    num_snippets = num_snippets,
    num_files = num_files,
    failures = {},
  }
  self.model.tasks = tasks
  -- self.view:draw(self.model)
end

function Controller:notify_conversion_completed(source_format, target_format, failures)
  print(2)
  local tasks = self.model.tasks or {}
  tasks[source_format].failures[target_format] = failures
  self.model.tasks = tasks
  self.view:draw(self.model)
end

return Controller

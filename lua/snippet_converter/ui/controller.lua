local snippet_engines = require("snippet_converter.snippet_engines")
local TaskState = require("snippet_converter.ui.task_state")
local view = require("snippet_converter.ui.view")

local Controller = {}

Controller.new = function()
  return setmetatable({}, { __index = Controller })
end

function Controller:create_view(model, settings)
  if self.view ~= nil then
    self.view:destroy()
  end
  self.model = model
  self.view = view.new(settings)
  self.view:open()
  self.view:draw(model, false, true)
end

function Controller:notify_conversion_started(source_format, num_snippets, num_input_files)
  local tasks = self.model.tasks or {}
  tasks[snippet_engines[source_format].label] = {
    state = TaskState.CONVERSION_STARTED,
    num_snippets = num_snippets,
    num_input_files = num_input_files,
    num_output_files = {},
    failures = {},
  }
  self.model.tasks = tasks
end

function Controller:notify_conversion_completed(
  source_format,
  target_format,
  num_output_files,
  failures
)
  -- TODO: set the model data in the model, not in the controller
  local tasks = self.model.tasks
  local source_label = snippet_engines[source_format].label
  local target_label = snippet_engines[target_format].label

  tasks[source_label].state = TaskState.CONVERSION_COMPLETED
  tasks[source_label].failures[target_label] = failures
  tasks[source_label].num_output_files[target_label] = num_output_files
  self.model.tasks = tasks
  self.model.max_num_failures = math.max(self.model.max_num_failures or 0, #failures)
end

function Controller:finalize()
  self.view:draw(self.model, false, false)
end

return Controller

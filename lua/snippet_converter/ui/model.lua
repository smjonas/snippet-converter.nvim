local snippet_engines = require("snippet_converter.snippet_engines")
local make_default_table = require("snippet_converter.utils.table").make_default_table

---@class Model
---@field templates table
---@field tasks table
---@field skipped_tasks table
---@field total_num_snippets integer
---@field total_num_failures integer
---@field output_files table<string>
---@field is_converting boolean
local Model = {}

Model.Status = {
  Success = 1,
  Warning = 2,
  Error = 3,
}

Model.Reason = {
  NO_INPUT_FILES = 1,
  NO_INPUT_SNIPPETS = 2,
}

Model.new = function()
  return setmetatable({
    templates = {},
    tasks = {},
    skipped_tasks = {},
    total_num_snippets = 0,
    total_num_failures = 0,
    output_files = {},
    is_converting = true,
  }, { __index = Model })
end

function Model:skip_task(template, source_format, reason)
  self.templates[template.name] = template
  make_default_table(self.skipped_tasks, template.name)[snippet_engines[source_format].label] = reason
end

function Model:did_skip_task(template, source_format)
  return self.skipped_tasks[template.name]
    and self.skipped_tasks[template.name][snippet_engines[source_format].label]
end

-- template.name must be non nil
function Model:submit_task(template, source_format, num_snippets, num_input_files, parser_errors)
  self.templates[template.name] = template
  self.total_num_snippets = self.total_num_snippets + num_snippets
  make_default_table(self.tasks, template.name)[snippet_engines[source_format].label] = {
    num_snippets = num_snippets,
    num_input_files = num_input_files,
    output_dirs = {},
    num_failures = 0,
    parser_errors = parser_errors,
    converter_errors = {},
    conversion_status = {},
    max_conversion_status = Model.Status.Success,
  }
end

function Model:complete_task(template, source_format, target_format, output_dirs, converter_errors)
  local source_label = snippet_engines[source_format].label
  local target_label = snippet_engines[target_format].label
  local tasks = self.tasks[template.name][source_label]

  local num_failures = #converter_errors
  tasks.num_failures = num_failures
  tasks.converter_errors[target_label] = converter_errors
  self.total_num_failures = self.total_num_failures + num_failures

  local status
  if num_failures == 0 then
    status = Model.Status.Success
  elseif num_failures == tasks.num_snippets then
    status = Model.Status.Error
  else
    status = Model.Status.Warning
  end
  tasks.conversion_status[target_label] = status
  tasks.max_conversion_status = math.max(tasks.max_conversion_status, status)

  tasks.output_dirs[target_label] = output_dirs
  self.max_num_failures = math.max(self.max_num_failures or 0, #converter_errors)
end

return Model

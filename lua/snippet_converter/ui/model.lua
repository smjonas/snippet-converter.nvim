local snippet_engines = require("snippet_converter.snippet_engines")

local M = {}

M.Status = {
  Success = 1,
  Warning = 2,
  Error = 3,
}

M.Reason = {
  NO_INPUT_FILES = 1,
  NO_INPUT_SNIPPETS = 2,
}

M.new = function()
  return setmetatable(
    { templates = {}, tasks = {}, skipped_tasks = {}, is_converting = true },
    { __index = M }
  )
end

function M:skip_task(template, source_format, reason)
  if not self.skipped_tasks[template.name] then
    self.skipped_tasks[template.name] = {}
  end
  self.skipped_tasks[template.name][snippet_engines[source_format].label] = reason
end

function M:did_skip_task(template, source_format)
  return self.skipped_tasks[template.name]
    and self.skipped_tasks[template.name][snippet_engines[source_format].label]
end

function M:submit_task(template, source_format, num_snippets, num_input_files, parser_errors)
  if not self.templates[template] then
    self.templates[#self.templates + 1] = template
  end
  if not self.tasks[template.name] then
    self.tasks[template.name] = {}
  end
  self.tasks[template.name][snippet_engines[source_format].label] = {
    num_snippets = num_snippets,
    num_input_files = num_input_files,
    num_output_files = {},
    parser_errors = parser_errors,
    converter_errors = {},
    conversion_status = {},
  }
end

function M:complete_task(template, source_format, target_format, num_output_files, converter_errors)
  local source_label = snippet_engines[source_format].label
  local target_label = snippet_engines[target_format].label
  local tasks = self.tasks[template.name][source_label]

  tasks.converter_errors[target_label] = converter_errors
  local num_failures = #converter_errors
  local status
  if num_failures == 0 then
    status = M.Status.Success
  elseif num_failures == tasks.num_snippets then
    status = M.Status.Error
  else
    status = M.Status.Warning
  end
  tasks.conversion_status[target_label] = status
  tasks.num_output_files[target_label] = num_output_files
  self.max_num_failures = math.max(self.max_num_failures or 0, #converter_errors)
end

return M

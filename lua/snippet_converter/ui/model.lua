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
  return setmetatable({ tasks = {}, skipped_tasks = {}, is_converting = true }, { __index = M })
end

function M:skip_task(source_format, reason)
  self.skipped_tasks[snippet_engines[source_format].label] = reason
end

function M:skipped_task(source_format)
  return self.skipped_tasks[snippet_engines[source_format].label]
end

function M:submit_task(source_format, num_snippets, num_input_files, parser_errors)
  self.tasks[snippet_engines[source_format].label] = {
    num_snippets = num_snippets,
    num_input_files = num_input_files,
    num_output_files = {},
    parser_errors = parser_errors,
    converter_errors = {},
    conversion_status = {},
  }
end

function M:complete_task(source_format, target_format, num_output_files, converter_errors)
  local source_label = snippet_engines[source_format].label
  local target_label = snippet_engines[target_format].label

  self.tasks[source_label].converter_errors[target_label] = converter_errors
  local num_failures = #converter_errors
  local status
  if num_failures == 0 then
    status = M.Status.Success
  elseif num_failures == self.tasks[source_label].num_snippets then
    status = M.Status.Error
  else
    status = M.Status.Warning
  end
  self.tasks[source_label].conversion_status[target_label] = status

  self.tasks[source_label].num_output_files[target_label] = num_output_files
  self.max_num_failures = math.max(self.max_num_failures or 0, #converter_errors)
end

return M

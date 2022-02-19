local snippet_engines = require("snippet_converter.snippet_engines")

local Model = {}

Model.new = function()
  return setmetatable({ tasks = {}, is_converting = true }, { __index = Model })
end

function Model:submit_task(source_format, num_snippets, num_input_files, parser_errors)
  self.tasks[snippet_engines[source_format].label] = {
    num_snippets = num_snippets,
    num_input_files = num_input_files,
    num_output_files = {},
    parser_errors = parser_errors,
    converter_errors = {},
  }
end

function Model:complete_task(source_format, target_format, num_output_files, converter_errors)
  local source_label = snippet_engines[source_format].label
  local target_label = snippet_engines[target_format].label

  self.tasks[source_label].converter_errors[target_label] = converter_errors
  self.tasks[source_label].num_output_files[target_label] = num_output_files
  self.max_num_failures = math.max(self.max_num_failures or 0, #converter_errors)
end

return Model

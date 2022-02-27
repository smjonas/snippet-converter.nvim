local M = {
  config = nil,
}

local snippet_engines, loader, Model
local controller

-- Setup function must be called before using the plugin!
M.setup = function(user_config)
  local cfg = require("snippet_converter.config")
  M.config = cfg.merge_config(user_config)
  cfg.validate(M.config)
  -- Load modules and create controller
  snippet_engines = require("snippet_converter.snippet_engines")
  loader = require("snippet_converter.core.loader")
  Model = require("snippet_converter.ui.model")
  controller = require("snippet_converter.ui.controller"):new()
end

-- Partitions the snippet paths into a table of <filetype, [snippet_paths]>
-- (e.g. filetype of an input file "lua.snippets" is "lua").

-- @param snippet_paths table<string> a list of snippet paths
-- @return <string, string> a table where each key is a filetype
-- and each value is a list of snippet paths that correspond to that filetype
local partition_snippet_paths = function(snippet_paths)
  local partitioned_snippet_paths = {}
  for _, snippet_path in ipairs(snippet_paths) do
    local filetype = vim.fn.fnamemodify(snippet_path, ":t:r")
    local snippet_paths_for_ft = partitioned_snippet_paths[filetype]
    if snippet_paths_for_ft == nil then
      snippet_paths_for_ft = {}
    end
    snippet_paths_for_ft[#snippet_paths_for_ft + 1] = snippet_path
    partitioned_snippet_paths[filetype] = snippet_paths_for_ft
  end
  return partitioned_snippet_paths
end

local load_snippets = function(sources)
  local snippet_paths = {}
  for source_format, source_paths in pairs(sources) do
    local _snippet_paths = loader.get_matching_snippet_paths(source_format, source_paths)
    snippet_paths[source_format] = partition_snippet_paths(_snippet_paths)
  end
  return snippet_paths
end

local parse_snippets = function(model, snippet_paths, template)
  local snippets = {}
  local context = {
    global_code = {},
  }
  for source_format, _ in pairs(template.sources) do
    snippets[source_format] = {}
    local num_snippets = 0
    local num_files = 0

    local parser = require(snippet_engines[source_format].parser)
    local parser_errors = {}
    for filetype, paths in pairs(snippet_paths[source_format]) do
      if snippets[source_format][filetype] == nil then
        snippets[source_format][filetype] = {}
      end
      for _, path in ipairs(paths) do
        num_snippets = parser.parse(path, snippets[source_format][filetype], parser_errors, context)
      end
      num_files = num_files + #paths
    end
    if num_files == 0 then
      model:skip_task(template, source_format, model.Reason.NO_INPUT_FILES)
    elseif num_snippets == 0 then
      model:skip_task(template, source_format, model.Reason.NO_INPUT_SNIPPETS)
    else
      model:submit_task(template, source_format, num_snippets, num_files, parser_errors)
    end
  end
  return snippets, context
end

local handle_snippet_transformation = function(transformation, snippet, source_format)
  local skip, converted_snippet
  local result = transformation(snippet, source_format)
  if result == nil then
    skip = true
  elseif type(result) == "table" then -- overwrites the snippet to be converted
    snippet = result
  elseif type(result) == "string" then -- overwrites the conversion result
    converted_snippet = result
  end
  return skip, converted_snippet
end

local convert_snippets = function(model, snippets, context, template)
  for source_format, snippets_for_format in pairs(snippets) do
    if not model:did_skip_task(template, source_format) then
      for target_format, output_paths in pairs(template.output) do
        local converter_errors = {}
        local converter = require(snippet_engines[target_format].converter)
        local converted_snippets = {}
        local pos = 1
        for filetype, _snippets in pairs(snippets_for_format) do
          for _, snippet in ipairs(_snippets) do
            local skip_snippet, converted_snippet
            -- TODO: fix for more than 1 template
            if template.transform_snippets then
              skip_snippet, converted_snippet = handle_snippet_transformation(
                template.transform_snippets,
                snippet,
                source_format
              )
            end
            if not skip_snippet then
              local ok = true
              if not converted_snippet then
                ok, converted_snippet = pcall(converter.convert, snippet, source_format)
                if not ok then
                  converter_errors[#converter_errors + 1] = {
                    msg = converted_snippet,
                    snippet = snippet,
                  }
                end
              end
              if ok then
                converted_snippets[pos] = converted_snippet
                pos = pos + 1
              end
            end
          end
          for _, output_path in ipairs(output_paths) do
            if filetype == snippet_engines[source_format].all_filename then
              filetype = snippet_engines[target_format].all_filename
            end
            converter.export(converted_snippets, filetype, output_path, context)
          end
        end
        print("Complete task", template.name)
        model:complete_task(template, source_format, target_format, #output_paths, converter_errors)
      end
    end
  end
end

-- Expose functions to tests
M._convert_snippets = convert_snippets

M.convert_snippets = function()
  if M.config == nil then
    error("setup function must be called before converting snippets")
    return
  end

  local model = Model.new()
  -- Make sure the window shows up before any potential long-running operations
  controller:create_view(model, M.config.settings)
  vim.schedule(function()
    for i, template in ipairs(M.config.templates) do
      if not template.name then
        template.name = i
      end
      local snippet_paths = load_snippets(template.sources)
      local snippets, context = parse_snippets(model, snippet_paths, template)
      convert_snippets(model, snippets, context, template)
    end
    controller:finalize()
  end)
  return model
end

return M

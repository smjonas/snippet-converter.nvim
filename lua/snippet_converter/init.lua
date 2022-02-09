local M = {}

local snippet_engines, loader, Model
local config, controller

local templates

-- Setup function must be called before using the plugin!
M.setup = function(user_config)
  local cfg = require("snippet_converter.config")
  config = cfg.merge_config(user_config)
  cfg.validate(config)
  templates = config.templates
  -- Load modules and create controller
  snippet_engines = require("snippet_converter.snippet_engines")
  loader = require("snippet_converter.core.loader")
  Model = require("snippet_converter.ui.model")
  controller = require("snippet_converter.ui.controller"):new()
end

M.add_template = function(template)
  local cfg = require("snippet_converter.config")
  cfg.validate_template(template)
  if not templates then
    templates = { template }
  else
    templates[#templates + 1] = template
  end
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

local parse_snippets = function(model, snippet_paths, sources)
  local snippets = {}
  for source_format, _ in pairs(sources) do
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
        local num_new_snippets = parser.parse(
          path,
          snippets[source_format][filetype],
          parser_errors
        )
        num_snippets = num_snippets + num_new_snippets
      end
      num_files = num_files + #paths
    end
    model:submit_task(source_format, num_snippets, num_files, parser_errors)
  end
  return snippets
end

local convert_snippets = function(model, snippets, output)
  for source_format, snippets_for_format in pairs(snippets) do
    local converter_errors = {}
    for target_format, output_paths in pairs(output) do
      local converter = require(snippet_engines[target_format].converter)
      local converted_snippets = {}
      local pos = 1
      for filetype, _snippets in pairs(snippets_for_format) do
        for _, snippet in ipairs(_snippets) do
          local ok, converted_snippet = pcall(converter.convert, snippet, source_format)
          if ok then
            converted_snippets[pos] = converted_snippet
            pos = pos + 1
          else
            converter_errors[#converter_errors + 1] = {
              msg = converted_snippet,
              snippet = snippet,
            }
          end
        end
        for _, output_path in ipairs(output_paths) do
          converter.export(converted_snippets, filetype, output_path)
        end
      end
      model:complete_task(source_format, target_format, #output_paths, converter_errors)
    end
  end
end

M.convert_snippets = function()
  if config == nil then
    error("setup function must be called with valid config before converting snippets")
    return
  end

  local model = Model.new()
  -- Make sure the window shows up before any potential long-running operations
  controller:create_view(model, config)

  vim.schedule(function()
    -- TODO
    local template = templates[1]
    local snippet_paths = load_snippets(template.sources)
    print(vim.inspect(snippet_paths))
    local snippets = parse_snippets(model, snippet_paths, template.sources)
    convert_snippets(model, snippets, template.output)
    controller:finalize()
    return model
  end)

end

return M

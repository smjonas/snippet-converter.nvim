local M = {
  config = nil,
}

local tbl = require("snippet_converter.utils.table")

local command, snippet_engines, loader, Model, string_utils
local controller

-- Setup function must be called before using the plugin!
M.setup = function(user_config)
  local cfg = require("snippet_converter.config")
  M.config = cfg.merge_config(user_config)
  cfg.validate(M.config)
  local template_names = {}
  for i, template in ipairs(M.config.templates) do
    -- Template names are optional, in that case use an integer
    if not template.name then
      -- This might cause duplicate names but let's not support that case
      template.name = tostring(i)
    end
    template_names[i] = template.name
    M.config.templates[i] = template
  end
  -- Load modules and create controller
  command = require("snippet_converter.command")
  snippet_engines = require("snippet_converter.snippet_engines")
  loader = require("snippet_converter.core.loader")
  Model = require("snippet_converter.ui.model")
  string_utils = require("snippet_converter.utils.string")
  controller = require("snippet_converter.ui.controller"):new()

  command.create_user_command(template_names, { "headless=" })
end

-- Partitions the snippet paths into a table of <filetype, [snippet_paths]>
-- (e.g. filetype of an input file "lua.snippets" gis "lua").

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

local load_snippets = function(template)
  local output_paths = {}
  for _, output in pairs(template.output) do
    for _, path in ipairs(output) do
      output_paths[#output_paths + 1] = path
    end
  end

  local snippet_paths = {}
  for source_format, source_paths in pairs(template.sources) do
    local _snippet_paths = loader.get_matching_snippet_paths(source_format, source_paths, output_paths)
    snippet_paths[source_format] = partition_snippet_paths(_snippet_paths)
  end
  return snippet_paths
end

local parse_snippets = function(model, snippet_paths, template)
  local snippets = {}
  local context = {
    global_code = {},
    include_filetypes = nil,
  }
  for source_format, _ in pairs(template.sources) do
    local format_opts = snippet_engines[source_format].format_opts
    local flavor = format_opts and format_opts.flavor

    snippets[source_format] = {}
    local num_snippets = 0

    local parser = require(snippet_engines[source_format].parser)
    local parser_errors = {}
    local all_input_files = {}
    for filetype, paths in pairs(snippet_paths[source_format]) do
      tbl.make_default_table(snippets[source_format], filetype)
      if parser.filter_paths then
        paths = parser.filter_paths(paths)
      end

      for _, path in ipairs(paths) do
        num_snippets = num_snippets
          + parser.parse(
            path,
            snippets[source_format][filetype],
            parser_errors,
            { context = context, flavor = flavor }
          )
      end

      tbl.concat_arrays(
        all_input_files,
        vim.tbl_map(function(path)
          return { format = source_format, path = path }
        end, paths)
      )
    end
    model.input_files = tbl.concat_arrays(model.input_files, all_input_files)

    local num_files = #all_input_files
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

local transform_snippets = function(transformation, snippet, helper, snippets_ptr)
  local should_delete = false
  -- Can return an optional flag whether to keep the current snippet or
  -- delete it (effectively replacing it with the new one)
  local result, opts = transformation(snippet, helper)
  if result == false then -- delete the snippet
    should_delete = true
  elseif result ~= nil then -- parse the string or table (for VScode snippets) and use the result of that
    opts = opts or {}
    local parsed_snippets = {}
    local parser_errors = {}
    if type(result) == "string" then
      result = vim.split(result, "\n")
    end
    local parser = require(snippet_engines[opts.format or helper.source_format].parser)
    parser.parse(nil, parsed_snippets, parser_errors, { lines = result })
    if #parser_errors > 0 then
      for _, err in ipairs(parser_errors) do
        local msg = type(err) == "table" and err.msg or err
        vim.notify(
          "[snippet-converter.nvim] error while parsing snippet in transform function: " .. msg,
          vim.log.levels.ERROR
        )
      end
    end
    if #parsed_snippets == 0 then
      vim.notify(
        "[snippet-converter.nvim] no valid snippets were found;"
          .. " please return a valid snippet string or table from the transform function",
        vim.log.levels.ERROR
      )
    else
      local pos = #snippets_ptr + 1
      for _, _snippet in ipairs(parsed_snippets) do
        -- A bit hacky but it works
        if snippet_engines[helper.target_format].base_format == "vscode" then
          _snippet.name = _snippet.trigger
        end
        snippets_ptr[pos] = _snippet
        pos = pos + 1
      end
      -- Default is true
      should_delete = opts.replace == nil and true or opts.replace
    end
  end
  return should_delete
end

local sort_snippets = function(format, template, snippets)
  -- Template > global > default sorting functions
  local sort_snippets = template.sort_snippets
    or M.config.sort_snippets
    or snippet_engines[format].default_sort_snippets

  if sort_snippets then
    table.sort(snippets, function(a, b)
      return sort_snippets(a, b)
    end)
  end
  -- If not set at this point, don't sort the snippets but output them in the order of appearance
end

local convert_snippets = function(model, snippets, context, template)
  local transform_helper = {
    dedent = string_utils.dedent,
  }
  local output_files = {}
  for target_format, output_dirs in pairs(template.output) do
    local filetypes = {}
    local converter = require(snippet_engines[target_format].converter)
    local format_opts = snippet_engines[target_format].format_opts

    for source_format, snippets_for_format in pairs(snippets) do
      if not model:did_skip_task(template, source_format) then
        local converter_errors = {}

        transform_helper.source_format = source_format
        transform_helper.target_format = target_format
        transform_helper.parser = require(snippet_engines[source_format].parser)

        for filetype, _snippets in pairs(snippets_for_format) do
          -- Contains converted snippets per filetype
          local converted_snippets = {}
          local pos = 1
          local skip_snippet = {}
          -- Apply local, then global transformations
          if template.transform_snippets or M.config.transform_snippets then
            local new_snippets = {}
            for i, snippet in ipairs(_snippets) do
              if template.transform_snippets then
                skip_snippet[i] =
                  transform_snippets(template.transform_snippets, snippet, transform_helper, new_snippets)
              end
              if M.config.transform_snippets and not skip_snippet[i] then
                skip_snippet[i] =
                  transform_snippets(M.config.transform_snippets, snippet, transform_helper, new_snippets)
              end
            end
            -- Append any snippets returned by the transformation functions
            tbl.concat_arrays(_snippets, new_snippets)
          end

          -- Remove skipped snippets
          tbl.compact(_snippets, skip_snippet)

          sort_snippets(source_format, template, _snippets)

          for _, snippet in ipairs(_snippets) do
            if not skip_snippet[snippet] then
              local ok, converted_snippet = pcall(converter.convert, snippet, nil, format_opts)
              if not ok then
                converter_errors[#converter_errors + 1] = {
                  msg = converted_snippet,
                  snippet = snippet,
                }
              else
                converted_snippets[pos] = converted_snippet
                pos = pos + 1
              end
            end
          end

          for _, output_path in ipairs(output_dirs) do
            if filetype == snippet_engines[source_format].global_filename then
              filetype = snippet_engines[target_format].global_filename
            end
            local path = converter.export(converted_snippets, filetype, output_path, context)
            output_files[#output_files + 1] = { format = target_format, path = path }
          end
          -- Store filetype in case they are needed (e.g. for creating package.json files)
          filetypes[#filetypes + 1] = filetype
        end
        model:complete_task(template, source_format, target_format, output_dirs, converter_errors)
      end
    end
    if converter.post_export then
      for _, output_path in ipairs(output_dirs) do
        converter.post_export(template, filetypes, output_path, context)
      end
    end
  end
  model.output_files = output_files
end

-- Expose functions to tests
M._parse_snippets = parse_snippets
M._convert_snippets = convert_snippets

M.convert_snippets = function(args)
  if M.config == nil then
    error("setup function must be called before converting snippets")
    return
  end
  local ok, parsed_args = command.validate_args(args or {}, M.config)
  if not ok then
    vim.notify(parsed_args, vim.log.levels.ERROR)
    return
  end

  local model = Model.new()
  if parsed_args.opts.headless or M.config.default_opts.headless and parsed_args.opts.headless ~= false then
    controller:create_headless_view(model)
  else
    -- Make sure the window shows up before any potential long-running operations
    controller:create_view(model, M.config.settings)
  end
  vim.schedule(function()
    for _, template in ipairs(parsed_args.templates) do
      local snippet_paths = load_snippets(template)
      local snippets, context = parse_snippets(model, snippet_paths, template)
      convert_snippets(model, snippets, context, template)
    end
    controller:finalize()
  end)
  return model
end

-- ## 1.2.0 (July 3, 2022)
-- Features:
-- - added snipmate_luasnip flavor which does not support converting Vimscript code
-- - if / else texts in VSCode format nodes are now supported
--
-- Bug fixes:
-- - fixed handling of newline characters in SnipMate snippet definitions (#3)
-- - fixed incorrect export when multiple filetypes were used (#4)
-- - fixed parsing of literal "endsnippet" keyword in UltiSnips parser
-- - fixed compatibility with Lua JIT and Lua 5.1 (#5)

-- ## 1.1.0 (May 2022)
-- Added vscode_luasnip flavor which supports luasnip-specific keys such as autotrigger and priorities.
--
-- ## 1.0.0 (May 2022)
-- Initial release of SnippetConverter! Currently supports UltiSnips, LuaSnip, SnipMate,
-- VSCode and vsnip snippets.
M.version = "1.2.0"

return M

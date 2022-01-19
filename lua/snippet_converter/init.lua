local M = {}
local snippet_engines = require("snippet_converter.snippet_engines")
local loader = require("snippet_converter.loader")

local function validate_sources(sources)
  vim.validate({
    sources = {
      sources,
      "table",
    },
  })
  local supported_formats = vim.tbl_keys(snippet_engines)
  for source_format, source_paths in ipairs(sources) do
    vim.validate({
      ["name of the source"] = {
        source_format,
        function(arg)
          return vim.tbl_contains(supported_formats, arg)
        end,
        "one of " .. vim.fn.join(supported_formats, ", "),
      },
    })
    for _, source_path in ipairs(source_paths) do
      vim.validate({
        source_path = {
          source_path,
          "string", -- TODO: support * as path to find all files matching extension in rtp
        },
      })
    end
  end
end

local config
M.setup = function(user_config)
  validate_sources(user_config.sources)
  config = user_config
end

-- Partitions the snippet paths into a table of <filetype, [snippet_paths]>
-- (e.g. filetype of an input file "lua.snippets" is "lua").

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

M.convert_snippets = function()
  if config == nil then
    error(
      "setup function must be called with valid config before converting snippets"
    )
    return
  end
  local snippet_paths = {}
  for source_format, source_paths in pairs(config.sources) do
    local _snippet_paths = loader.get_matching_snippet_paths(source_format, source_paths)
    snippet_paths[source_format] = partition_snippet_paths(_snippet_paths)
  end

  local snippets = {}
  for source_format, _ in pairs(config.sources) do
    local parser = require(snippet_engines[source_format].parser)
    for filetype, paths in pairs(snippet_paths[source_format]) do
      -- Collect the snippet definitions from all input files
      if snippets[filetype] == nil then
        snippets[filetype] = {}
      end
      for _, path in ipairs(paths) do
        snippets[filetype][#snippets[filetype] + 1] = parser.parse(parser.get_lines(path))
      end
    end
  end
  print(vim.inspect(snippets))

--     vim.fn.flatten(snippets, 1)
--     snippets_for_format[source_format] = partition_snippets(snippets)
--   end
--   print(vim.inspect(snippets_for_format["ultisnips"]))

--   -- Convert every snippet to all of the specified output formats
--   for target_format, output_path in ipairs(config.output) do
--     local converter = require(snippet_engines[target_format].converter)
--     local converted_snippets = {}
--     for _, snippet in ipairs(snippets_for_format) do
--       converted_snippets[#converted_snippets + 1] = converter.convert(snippet)
--     end
--     converter.export(converted_snippets, output_path)
--   end
end

return M

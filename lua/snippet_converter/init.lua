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

M.convert_snippets = function()
  if config == nil then
    error(
      "[snippet_converter.nvim] setup function must be called with valid config before converting snippets"
    )
    return
  end
  local snippets_for_format = {}
  for source_format, source_paths in pairs(config.sources) do
    local snippet_paths = loader.get_matching_snippet_files(source_format, source_paths)
    local parser = require(snippet_engines[source_format].parser)
    local snippets = {}
    -- Collect the snippet definitions from all input files into a single table
    for _, path in ipairs(snippet_paths) do
      snippets[#snippets + 1] = parser.parse(parser.get_lines(path))
    end
    vim.fn.flatten(snippets, 1)
    snippets_for_format[source_format] = snippets
  end

  -- Convert every snippet to all of the specified output formats
  for target_format, output_path in ipairs(config.output) do
    local converter = require(snippet_engines[target_format].converter)
    local converted_snippets = {}
    for _, snippet in ipairs(snippets_for_format) do
      converted_snippets[#converted_snippets + 1] = converter.convert(snippet)
    end
    converter.export(converted_snippets, output_path)
  end
end

return M

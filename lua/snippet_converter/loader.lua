local snippet_engines = require("snippet_converter.snippet_engines")
local utils = require("snippet_converter.utils")

local loader = {}

local function find_matching_snippet_files_in_rtp(
  matching_snippet_files,
  source_format,
  source_path
)
  local tail = snippet_engines[source_format].extension
  local first_slash_pos = source_path and source_path:find("/")

  local root_folder
  if first_slash_pos then
    root_folder = source_path:sub(1, first_slash_pos - 1)
    tail = source_path:sub(first_slash_pos + 1) .. tail
  else
    root_folder = source_path
  end

  local rtp_files = vim.api.nvim_get_runtime_file(tail, true)

  -- Turn glob pattern (with potential wildcards) into lua pattern
  local file_pattern = string.format("%s/%s", root_folder, tail)
    :gsub("([^%w%*])", "%%%1")
    :gsub("%*", ".-") .. "$"

  for _, file in pairs(rtp_files) do
    if file:match(file_pattern) then
      matching_snippet_files[#matching_snippet_files + 1] = file
    end
  end
end

local function get_matching_snippet_files(source_format, source_paths)
  local matching_snippet_files = {}
  for _, source_path in pairs(source_paths) do
    if utils.file_exists(source_path) then
      matching_snippet_files[#matching_snippet_files + 1] = source_path
    else
      find_matching_snippet_files_in_rtp(matching_snippet_files, source_format, source_path)
    end
  end
  return matching_snippet_files
end

local function validate_config(sources)
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

loader.load = function(config)
  validate_config(config)
  for source_format, source_paths in pairs(config.sources) do
    local snippet_paths = get_matching_snippet_files(source_format, source_paths)
    local parser = require(snippet_engines[source_format].parser)
    for _, path in ipairs(snippet_paths) do
      P(parser.parse(parser.get_lines(path)))
      return
    end
  end
end

return loader

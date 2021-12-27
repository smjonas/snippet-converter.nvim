local utils = require("snippet_converter.utils")

local loader = {}

-- TODO: rename to snippet engine (format)?
local supported_formats = {
  "snipmate",
  "ultisnips",
  "vscode",
}

local parsers = {
  snipmate = {
    extension = "*.snippets",
    parser = "snippet_converter.snipmate.parser"
  },
  ultisnips = {
    extension = "*.snippets",
    parser = "snippet_converter.ultisnips.parser",
  },
  vscode = {
    extension = "*.json",
    parser = "snippet_converter.vscode.parser",
  },
}

local function find_matching_snippet_files_in_rtp(matching_snippet_files, source_format, source_path)
  local tail = parsers[source_format].extension
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
  for source_format, source_paths in ipairs(sources) do
    vim.validate({
      format = {
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
        }
      })
    end
  end
end

loader.load = function(config)
  validate_config(config)
  for source_format, source_paths in pairs(config.sources) do
    local snippet_paths = get_matching_snippet_files(source_format, source_paths)
    local parser = require(parsers[source_format].parser)
    for _, path in ipairs(snippet_paths) do
      parser.parse(parser.get_lines(path))
      return
    end
  end
end

return loader

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

  print(source_path)

  local root_folder
  if first_slash_pos then
    root_folder = source_path:sub(1, first_slash_pos - 1)
    -- TODO: handle case when source_path does not end with "/"!
    tail = source_path:sub(first_slash_pos + 1) .. tail
  else
    root_folder = source_path
  end

  print(root_folder)
  print(tail .. " a ")
  local rtp_files = vim.api.nvim_get_runtime_file(tail, true)
  print(vim.inspect(rtp_files))
  -- Turn glob pattern (with potential wildcards) into lua pattern
  local file_pattern = string.format("%s/%s", root_folder, tail)
    :gsub("([^%w%*])", [[%%1]])
    :gsub("%*", ".-") .. "$"

  for _, file in pairs(rtp_files) do
    if file:match(file_pattern) then
      matching_snippet_files[#matching_snippet_files + 1] = file
    end
  end
  print(vim.inspect(matching_snippet_files))
end

loader.get_matching_snippet_files = function(source_format, source_paths)
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

return loader

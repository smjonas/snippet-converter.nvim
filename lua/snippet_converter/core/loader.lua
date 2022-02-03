local snippet_engines = require("snippet_converter.snippet_engines")
local utils = require("snippet_converter.utils.file_utils")

local loader = {}

local function find_matching_snippet_files_in_rtp(
  matching_snippet_files,
  source_format,
  source_path
)
  -- Turn glob pattern (with potential wildcards) into lua pattern;
  -- escape all non-alphanumeric characters to be safe
  local file_pattern = source_path:gsub("([^%w%*])", "%%%1"):gsub("%*", ".-")

  local extension = snippet_engines[source_format].extension
  local rtp_files = vim.api.nvim_get_runtime_file("*/*" .. extension, true)

  for _, file in pairs(rtp_files) do
    if file:match(file_pattern) then
      matching_snippet_files[#matching_snippet_files + 1] = file
    end
  end
end

-- Searches for a set of snippet files on the user's system for a specific snippet engine
-- that match the given paths.
--
-- @param source_format string a valid source format that will be used to determine the
-- extension of the snippet files (e.g. "ultisnips")
-- @param source_paths list<string> a list of paths to search for in the runtimepath as
-- well as the system (e.g. "vim-snippets/snippets"); may contain wildcards ("*")
-- @return list<string> a list containing the absolute paths to the matching snippet files
loader.get_matching_snippet_paths = function(source_format, source_paths)
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

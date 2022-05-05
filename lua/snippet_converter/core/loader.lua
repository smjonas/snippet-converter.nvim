local snippet_engines = require("snippet_converter.snippet_engines")
local io = require("snippet_converter.utils.io")

local M = {}

local find_matching_snippet_files = function(matching_snippet_files, source_format, source_path)
  local extension = snippet_engines[source_format].extension
  -- ./ indicates to look for files in the runtimepath
  local rt_path = source_path:match("%./(.*)")
  if rt_path then
    -- Turn path into Lua pattern
    local rt_path_pattern = vim.pesc(rt_path)
    local rtp_files = vim.api.nvim_get_runtime_file("*/*" .. extension, true)
    for _, name in ipairs(rtp_files) do
      -- Name can either be a directory or a file name so make sure it is a file
      if name:match(rt_path_pattern) and io.file_exists(name) then
        matching_snippet_files[#matching_snippet_files + 1] = name
      end
    end
  else
    for _, file in ipairs(io.scan_dir(vim.fn.expand(source_path), extension)) do
      matching_snippet_files[#matching_snippet_files + 1] = file
    end
  end
end

-- Searches for a set of snippet files on the user's system with a given extension
-- that matches the source format.
--
-- @param source_format string a valid source format that will be used to determine the
-- extension of the snippet files (e.g. "ultisnips")
-- @param source_paths list<string> a list of paths to search for; if a path is a
-- absolute path to a file it will be added directly, if a path starts with
-- "./" the search starts in the runtimepath, otherwise the search will start at the given
-- root directory and match any files with the correct extension
-- @return list<string> a list containing the absolute paths to the matching snippet files
M.get_matching_snippet_paths = function(source_format, source_paths)
  local matching_snippet_files = {}
  for _, source_path in pairs(source_paths) do
    if io.file_exists(source_path) then
      matching_snippet_files[#matching_snippet_files + 1] = source_path
    else
      find_matching_snippet_files(matching_snippet_files, source_format, source_path)
    end
  end
  return matching_snippet_files
end

return M

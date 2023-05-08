local snippet_engines = require("snippet_converter.snippet_engines")
local io = require("snippet_converter.utils.io")

--- @class Loader
local M = {}

local match_any = function(s, paths)
  for _, path in ipairs(paths) do
    if s:match(vim.fn.expand(path)) then
      return true
    end
  end
  return false
end

-- @param matching_snippet_files table<SnippetLocation>
local add_location = function(matching_snippet_files, source_format, snippet_path)
  local filetype
  if source_format == "yasnippet" then
    -- Get filetype from <filetype>-mode root folder
    filetype = io.get_containing_folder(snippet_path):match("/([^/]-)%-mode")
  else
    -- Get filetype from <filetype>.<extension> filename
    filetype = vim.fn.fnamemodify(snippet_path, ":t:r")
  end
  if filetype then
    table.insert(matching_snippet_files, { path = snippet_path, filetype = filetype })
  end
end

-- @param matching_snippet_files table<SnippetLocation>
local find_matching_snippet_files = function(
  matching_snippet_files,
  source_format,
  source_path,
  exclude_paths
)
  local extension = snippet_engines[source_format].extension
  -- ./ indicates to look for files in the runtimepath
  local rt_path = source_path:match("%./(.*)")
  if rt_path then
    -- Turn path into Lua pattern
    local rt_path_pattern = vim.pesc(rt_path)
    local rtp_files = vim.api.nvim_get_runtime_file("*/*" .. extension, true)
    for _, name in ipairs(rtp_files) do
      -- Do not include paths that match exclude_paths: this would lead to reconverting
      -- the same snippets in consecutive runs if the paths are also set as output paths
      -- Name can either be a directory or a file name so make sure it is a file
      if name:match(rt_path_pattern) and not match_any(name, exclude_paths) and io.file_exists(name) then
        add_location(matching_snippet_files, source_format, name)
      end
    end
  else
    local files = io.scan_dir(vim.fn.expand(source_path), extension, {
      -- Should probably be made configurable
      recursive = source_format == "yasnippet",
    })
    for _, file in ipairs(files) do
      add_location(matching_snippet_files, source_format, file)
    end
  end
end

--- Searches for a set of snippet files on the user's system with a given extension
--- that matches the source format.
---
--- @param source_format string a valid source format that will be used to determine the
--- extension of the snippet files (e.g. "ultisnips")
--- @param source_paths table<string> a list of paths to search for; if a path is a
--- absolute path to a file it will be added directly, if a path starts with
--- "./" the search starts in the runtimepath, otherwise the search will start at the given
--- root directory and match any files with the correct extension
--- @param exclude_paths table<string> a list of snippet paths to exclude
--- @return table<SnippetLocation> #a list containing the absolute paths and filetypes to the matching snippet files
M.get_matching_snippet_paths = function(source_format, source_paths, exclude_paths)
  --- @class SnippetLocation
  --- @field path string
  --- @field filetype string

  --- @type table<SnippetLocation>
  local matching_snippet_files = {}
  for _, source_path in pairs(source_paths) do
    if io.file_exists(source_path) then
      add_location(matching_snippet_files, source_format, source_path)
    else
      find_matching_snippet_files(matching_snippet_files, source_format, source_path, exclude_paths)
    end
  end
  return matching_snippet_files
end

return M

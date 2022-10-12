local M = {}

local tbl = require("snippet_converter.utils.table")

local uv = vim.loop

M.file_exists = function(path)
  return vim.fn.filereadable(vim.fn.expand(path)) == 1
end

M.folder_exists = function(path)
  return vim.fn.isdirectory(vim.fn.expand(path)) == 1
end

M.get_containing_folder = function(path)
  return vim.fn.fnamemodify(path, ":p:h")
end

M.join = function(...)
  -- Let's simply pretend Windows doesn't exist
  -- (actually, Windows should handle forward slashes just fine)
  return table.concat({ ... }, "/")
end

-- Scans the given root directory for files with the specified extension and returns them.
---@param root string
---@param opts table? with the following keys:
--        - recursive (boolean) if true, all subdirectories will be scanned as well
---@return string[] files
M.scan_dir = function(root, extension, opts)
  opts = opts or {}
  local files = {}
  local dirs = {}
  local fs = uv.fs_scandir(root)
  if fs then
    local name = ""
    local type
    while name do
      name, type = uv.fs_scandir_next(fs)
      local path = M.join(root, name)
      if type == "file" then
        -- Match file without extension
        if extension == "" and path:match("[^.]+") then
          table.insert(files, path)
        else
          local _, ext = path:match("(.*)%.(.+)")
          if ext == extension then
            table.insert(files, path)
          end
        end
      elseif type == "directory" then
        table.insert(dirs, path)
      elseif type == "link" then
        local followed_path = uv.fs_realpath(path)
        if followed_path then
          local stat = uv.fs_stat(followed_path)
          if stat.type == "file" then
            local _, ext = path:match("(.*)%.(.+)")
            if ext == extension then
              table.insert(files, path)
            end
          end
        end
      end
    end
  end

  if opts.recursive then
    for _, sub_dir in ipairs(dirs) do
      local sub_files, sub_dirs = M.scan_dir(sub_dir, extension, opts)
      files = tbl.concat_arrays(files, sub_files)
      dirs = tbl.concat_arrays(dirs, sub_dirs)
    end
  end
  return files, dirs
end

M.read_file = function(path)
  -- Replace this with libuv's uv.read_file? However, in that case we only get the raw
  -- buffer content and would need to split the string it to get the lines.
  return vim.fn.readfile(vim.fn.expand(path))
end

M.write_file = function(object, path)
  path = vim.fn.expand(path)
  local dir_name = vim.fn.fnamemodify(path, ":p:h")
  -- Create missing directories (if any)
  if vim.fn.isdirectory(dir_name) ~= 1 then
    vim.fn.mkdir(dir_name, "p")
  end
  vim.fn.writefile(object, path)
end

M.read_json = function(path)
  local lines = table.concat(M.read_file(path), "\n")
  return vim.json.decode(lines)
end

return M

local M = {}

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

-- Recursively scans the given root directory for files with the specified extension and returns them.
---@param root string
---@return string[] files
M.scan_dir = function(root, extension)
  local files = {}
  local fs = uv.fs_scandir(root)
  if fs then
    local name, type = "", ""
    while name do
      name, type = uv.fs_scandir_next(fs)
      local path = M.join(root, name)
      if type == "file" then
        local _, ext = path:match("(.*)%.(.+)")
        if ext == extension then
          files[#files + 1] = path
        end
      elseif type == "link" then
        local followed_path = uv.fs_realpath(path)
        if followed_path then
          local stat = uv.fs_stat(followed_path)
          if stat.type == "file" then
            local _, ext = path:match("(.*)%.(.+)")
            if ext == extension then
              files[#files + 1] = path
            end
          end
        end
      end
    end
  end
  return files
end

M.read_file = function(path)
  -- Replace this with libuv's uv.read_file? However, in that case we only get the raw
  -- buffer content and would need to split the string it to get the lines.
  return vim.fn.readfile(vim.fn.expand(path))
end

M.write_file = function(object, path)
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

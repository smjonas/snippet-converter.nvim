local M = {}

M.make_default_table = function(tbl, key)
  if key == nil then
    error("table.make_default_table: key is nil for table " .. vim.inspect(tbl))
  end
  return setmetatable(tbl, {
    __index = function(_, actual_key)
      if key == actual_key then
        tbl[key] = {}
      end
      return tbl[key]
    end,
  })[key]
end

-- Removes all gaps in the array
M.compact = function(arr, gaps)
  for i = #arr, 1, -1 do
    if gaps[i] then
      arr[i] = arr[#arr]
      arr[#arr] = nil
    end
  end
end

return M

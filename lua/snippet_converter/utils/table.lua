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

-- Returns an iterator that yields all items in the table in the order specified by compare.
M.pairs_by_keys = function(tbl, compare)
  local keys = {}
  for key, _ in pairs(tbl) do
    table.insert(keys, key)
  end
  compare = compare or function(a, b)
    return a:lower() < b:lower()
  end
  table.sort(keys, compare)
  local i = 0
  -- Return an iterator function
  return function()
    i = i + 1
    return keys[i] and keys[i], tbl[keys[i]] or nil
  end
end

return M

local converter = {}

function converter.create()
  local self = setmetatable({}, { __index = converter })
  return self
end

return converter

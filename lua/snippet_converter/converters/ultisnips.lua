local converter = {}

function converter.create()
  local self = setmetatable({}, { __index = converter })
  return self
end

-- Take ultisnips and output base
function converter.convert_to_base(snippets)

end

-- Take base and output ultisnips
function converter.convert_from_base(snippets)

end



return converter

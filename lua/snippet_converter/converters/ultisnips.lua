local converter = {}

function converter.create()
  local self = setmetatable({}, { __index = converter })
  return self
end

function converter.convert(snippet)
  local trigger = snippet.trigger
  -- Literal " in trigger
  if trigger:match([["]]) then
    trigger = string.format("!%s!", trigger)
    -- Multi-word trigger
  elseif trigger:match("%s") then
    trigger = string.format([["%s"]], trigger)
  end
  local description = ""
  -- Description must be quoted
  if snippet.description then
    description = string.format([[ "%s"]], snippet.description)
  end
  local body = vim.fn.join(snippet.body, "\n")
  return string.format("snippet %s%s\n%s\nendsnippet", trigger, description, body)
end

return converter

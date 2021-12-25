local converter = {}

-- Determines whether the provided snippet can be converted from UltiSnips
-- to other formats (e.g. python interpolation is an UltiSnips-only feature).
function converter.can_convert(snippet, target_engine)
  local body = vim.fn.join(snippet.body, "")
  -- Must not contain interpolation code
  return not body:match("`[^`]*`")
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

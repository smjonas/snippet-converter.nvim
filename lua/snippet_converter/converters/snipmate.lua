local converter = {}

local function can_convert(snippet, _)
  -- Must not contain multi-word trigger
  return not snippet.trigger:match("%s")
end

function converter.convert(snippet, target_engine)
  if not can_convert(snippet, target_engine) then
    return
  end
  local description = ""
  if snippet.description then
    description = " " .. snippet.description
  end
  local body = vim.fn.join(snippet.body, "\n\t")
  return string.format("snippet %s%s\n\t%s", snippet.trigger, description, body)
end

return converter

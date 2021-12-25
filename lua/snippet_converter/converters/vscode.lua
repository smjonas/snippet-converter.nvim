local converter = {}

function converter.convert(snippet)
  local name
  if snippet.description then
    name = snippet.description
  else
    name = snippet.trigger
  end
  return {
    name = name,
    prefix = { snippet.trigger },
    description = snippet.description,
    body = snippet.body,
  }
end

return converter

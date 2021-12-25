local converter = {}

function converter.convert(snippet)
  local description = ""
  if snippet.description then
    description = " " .. snippet.description
  end
  local body = vim.fn.join(snippet.body, "\n\t")
  return string.format("snippet %s%s\n\t%s\n\n", snippet.trigger, description, body)
end

return converter

local loader = {}

local parser = require("snippet_hub.loaders.ultisnips.parser")

loader.load = function(snippet_paths)
  local loaded_snippets = {}
  local cur_snippet
  for _, path in pairs(snippet_paths) do
    local content = vim.fn.readfile(path)
    local found_snippet_header = false

    for _, line in ipairs(content) do
      if not found_snippet_header then
        local stripped_header = line:match("^%s*snippet%s+(.-)%s*$")
        -- Found possible snippet header
        if stripped_header ~= nil then
          local header = parser.parse_snippet_header(stripped_header)
          if not vim.tbl_isempty(header) then
            cur_snippet = header
            cur_snippet.body = {}
            found_snippet_header = true
          end
        end
      elseif found_snippet_header and line:match("^endsnippet") ~= nil then
        loaded_snippets[#loaded_snippets + 1] = cur_snippet
        found_snippet_header = false
      elseif found_snippet_header then
        table.insert(cur_snippet.body, line)
      end
    end
    return loaded_snippets
  end
end

return loader

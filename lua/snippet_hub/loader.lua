local loader = {}

local snippet_file_extensions = {
  ultisnips = "*/*.snippets",
}

local function get_matching_snippet_files(source)
  local source_path = source[1]
  local tail = snippet_file_extensions[source.format]
  local first_slash_pos = source_path and source_path:find("/")

  local root_folder
  if first_slash_pos then
    root_folder = source_path:sub(1, first_slash_pos - 1)
    tail = source_path:sub(first_slash_pos + 1) .. tail
  else
    root_folder = source_path
  end

  local matching_snippet_files = {}
  local rtp_files = vim.api.nvim_get_runtime_file(tail, true)

  -- Turn glob pattern with potential wildcards into lua pattern
  local file_pattern = string.format("%s/%s", root_folder, tail)
  :gsub("([^%w%*])", "%%%1"):gsub("%*", ".-") .. "$"

  for _, file in pairs(rtp_files) do
    if file:match(file_pattern) then
      matching_snippet_files[#matching_snippet_files + 1] = file
    end
  end
end

loader.load = function(source)
  local snippet_files = get_matching_snippet_files(source)
end

return loader

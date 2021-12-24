local loader = {}

-- TODO: rename to snippet engine (format)?
local supported_formats = {
  "ultisnips", "snipmate"
}

local parsers = {
  ultisnips = {
    extension = "*/*.snippets",
    parser = require("snippet_converter.parsers.ultisnips")
  },
}

local function get_matching_snippet_paths(source)
  local source_path = source[1]
  local tail = parsers[source.format].extension
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

  -- Turn glob pattern (with potential wildcards) into lua pattern
  local file_pattern = string.format("%s/%s", root_folder, tail)
    :gsub("([^%w%*])", "%%%1"):gsub("%*", ".-") .. "$"

  for _, file in pairs(rtp_files) do
    if file:match(file_pattern) then
      matching_snippet_files[#matching_snippet_files + 1] = file
    end
  end
  return matching_snippet_files
end

local function validate_source(source)
  vim.validate({
    source = {
      source, "table"
    },
    format = {
      source.format,
      function(arg)
        return vim.tbl_contains(supported_formats, arg)
      end,
      "one of " .. vim.fn.join(supported_formats, ", ")
    },
    source_path = {
      source[1],
      function(arg)
        return not arg or type(arg) == "string"
      end,
      "nil or string"
    },
  })
end

loader.load = function(source)
  validate_source(source)
  local snippet_paths = get_matching_snippet_paths(source)
  local parser = parsers[source.format].parser
  for _, path in pairs(snippet_paths) do
    P(parser:parse(path))
  end
end

return loader

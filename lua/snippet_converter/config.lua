local config = {}

local default_settings = {
  use_nerdfont_icons = true,
}

config.validate_settings = function(settings)
  vim.validate {
    use_nerdfont_icons = { settings.use_nerdfont_icons, "boolean" },
  }
end

config.merge_settings = function(user_settings)
  return vim.tbl_deep_extend("force", default_settings, user_settings)
end

config.validate_sources = function(sources, snippet_engines)
  vim.validate {
    sources = {
      sources,
      "table",
    },
  }
  local supported_formats = vim.tbl_keys(snippet_engines)
  for source_format, source_paths in ipairs(sources) do
    vim.validate {
      ["name of the source"] = {
        source_format,
        function(arg)
          return vim.tbl_contains(supported_formats, arg)
        end,
        "one of " .. vim.fn.join(supported_formats, ", "),
      },
    }
    for _, source_path in ipairs(source_paths) do
      vim.validate {
        source_path = {
          source_path,
          "string", -- TODO: support * as path to find all files matching extension in rtp
        },
      }
    end
  end
end

return config

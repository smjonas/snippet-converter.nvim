local M = {}

local snippet_engines = require("snippet_converter.snippet_engines")

local DEFAULT_CONFIG = {
  use_nerdfont_icons = true,
}

M.validate_sources = function(sources)
  -- The user might choose to call add_pipeline after the initial call to setup, thus sources may be nil.
  if sources == nil then
    return
  end
  vim.validate {
    sources = {
      sources,
      "table",
    },
  }
  local supported_formats = vim.tbl_keys(snippet_engines)
  for source_format, source_paths in ipairs(sources) do
    vim.validate {
      source_format = {
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

local validate_settings = function(settings)
  vim.validate {
    settings = {
      settings,
      "table",
      true,
    },
  }
  if settings == nil then
    return
  end
  vim.validate {
    ui = {
      settings.ui,
      "table",
      true,
    },
  }
  if settings.ui then
    vim.validate {
      use_nerdfont_icons = {
        settings.ui.use_nerdfont_icons,
        "boolean",
        true,
      },
    }
  end
end

M.validate = function(user_config)
  vim.validate {
    config = {
      user_config,
      "table",
    },
  }
  M.validate_sources(user_config.sources)
  validate_settings(user_config.settings)
end

M.merge_config = function(user_config)
  return vim.tbl_deep_extend("force", DEFAULT_CONFIG, user_config)
end

return M

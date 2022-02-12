local M = {}

local snippet_engines = require("snippet_converter.snippet_engines")

M.DEFAULT_CONFIG = {
  use_nerdfont_icons = true,
}

local validate_table = function(name, tbl, is_optional)
  vim.validate {
    [name] = {
      tbl,
      "table",
      is_optional
    }
  }
end

local validate_paths = function(name, paths_for_format, format_name, path_name)
  validate_table(name, paths_for_format)
  local supported_formats = vim.tbl_keys(snippet_engines)
  for format, paths in pairs(paths_for_format) do
    vim.validate {
      [format_name] = {
        format,
        function(arg)
          return vim.tbl_contains(supported_formats, arg)
        end,
        "one of " .. vim.fn.join(supported_formats, ", "),
      },
    }
    validate_table("source.paths", paths)
    for _, path in ipairs(paths) do
      vim.validate {
        [path_name] = {
          path,
          "string", -- TODO: support * as path to find all files matching extension in rtp
        },
      }
    end
  end
end

local validate_template = function(template)
  validate_table("template", template)
  validate_paths("template.sources", template.sources, "source.format", "source.path")
  validate_paths("template.output", template.output, "output.format", "output.path")
end

local validate_templates = function(templates)
  validate_table("templates", templates)
  for _, template in ipairs(templates) do
    validate_template(template)
  end
end

local validate_settings = function(settings)
  validate_table("settings", settings, true)
  if settings == nil then
    return
  end
  validate_table("settings.ui", settings.ui, true)
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
  validate_table("config", user_config)
  validate_templates(user_config.templates)
  validate_settings(user_config.settings)
end

M.merge_config = function(user_config)
  return vim.tbl_deep_extend("force", M.DEFAULT_CONFIG, user_config)
end

return M

local M = {}

local snippet_engines = require("snippet_converter.snippet_engines")

M.DEFAULT_CONFIG = {
  settings = {
    ui = {
      use_nerdfont_icons = true,
    },
  },
  default_opts = {
    headless = false,
  },
}

M.DEFAULT_TEMPLATE_CONFIG = {
  compare = function(first, second)
    return first:lower() < second:lower()
  end,
}

local validate_table = function(name, tbl, is_optional)
  vim.validate {
    [name] = {
      tbl,
      "table",
      is_optional,
    },
  }
end

local validate_paths = function(name, paths_for_format, format_name, path_name)
  validate_table(name, paths_for_format)
  local supported_formats = vim.tbl_keys(snippet_engines)
  vim.validate {
    [name] = {
      paths_for_format,
      function(tbl)
        return #vim.tbl_keys(tbl) > 0
      end,
      "non-empty table",
    },
  }
  for format, paths in pairs(paths_for_format) do
    vim.validate {
      [("%s for %s"):format(name, format)] = {
        paths,
        function(tbl)
          return #tbl > 0
        end,
        "non-empty array",
      },
    }
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
          "string",
        },
      }
    end
  end
end

local validate_template = function(template)
  validate_table("template", template)
  vim.validate {
    ["template.name"] = {
      template.name,
      function(arg)
        return not arg or not arg:match("%s")
      end,
      "nil or string without whitespace",
    },
  }
  validate_paths("template.sources", template.sources, "source.format", "source.path")
  validate_paths("template.output", template.output, "output.format", "output.path")
  vim.validate {
    ["template.sort_by"] = {
      template.sort_by,
      "function",
      true,
    },
  }
  vim.validate {
    ["template.compare"] = {
      template.compare,
      "function",
      true,
    },
  }
end

local validate_templates = function(templates)
  validate_table("templates", templates)
  for _, template in ipairs(templates) do
    validate_template(template)
  end
end

local validate_settings = function(settings)
  if settings == nil then
    return
  end
  validate_table("settings", settings, false)
  validate_table("settings.ui", settings.ui, true)
  if settings.ui then
    vim.validate {
      ["settings.ui.use_nerdfont_icons"] = {
        settings.ui.use_nerdfont_icons,
        "boolean",
        true,
      },
    }
  end
end

local validate_default_opts = function(default_opts)
  if default_opts == nil then
    return
  end
  validate_table("default_opts", default_opts, false)
  vim.validate {
    ["default_opts.headless"] = {
      default_opts.headless,
      "boolean",
    },
  }
end

M.validate = function(user_config)
  validate_table("config", user_config)
  validate_templates(user_config.templates)
  validate_settings(user_config.settings)
  validate_default_opts(user_config.defaults)
  vim.validate {
    transform_snippets = {
      user_config.transform_snippets,
      "function",
      true,
    },
  }
end

M.merge_config = function(user_config)
  return vim.tbl_deep_extend("force", M.DEFAULT_CONFIG, user_config)
end

M.merge_template_config = function(user_template)
  return vim.tbl_deep_extend("force", M.DEFAULT_TEMPLATE_CONFIG, user_template)
end

return M

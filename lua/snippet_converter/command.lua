local M = {}

local tbl = require("snippet_converter.utils.table")

local CmdOpts = {
  headless = 1,
}

--- Creates the ConvertSnippets user command.
---@param template_names table<string> a list of template_names to complete
---@param options table<string> a list of options to complete
M.create_user_command = function(template_names, options)
  tbl.concat_arrays(template_names, options)
  vim.api.nvim_create_user_command("ConvertSnippets", function(result)
    require("snippet_converter").convert_snippets(result.fargs)
  end, {
    nargs = "*",
    complete = function(arglead, _, _)
      -- Currently there is only one option
      if arglead:find("^headless=") then
        return { "headless=true", "headless=false" }
      end
      -- Only complete arguments that start with arglead
      return vim.tbl_filter(function(arg)
        return arg:match("^" .. arglead)
      end, template_names)
    end,
  })
end

---@return boolean ok
---@return table | string templates and opts table or error message
M.validate_args = function(args, config)
  local templates = {}
  local opts = {}
  local template_with_name = {}
  local template_names = {}
  for i, template in ipairs(config.templates) do
    template_with_name[template.name] = template
    template_names[i] = template.name
  end

  for _, arg in ipairs(args) do
    local key, value = arg:match("%-%-(.+)=(.+)")
    if key then
      if not CmdOpts[key] then
        return false, ("[snippet-converter.nvim] unknown option '%s'"):format(arg)
      end
      if value ~= "true" and value ~= "false" then
        return false, ("[snippet-converter.nvim] invalid option value '%s'"):format(value)
      end
      opts[key] = value == "true" and true or false
    else
      if template_with_name[arg] then
        templates[#templates + 1] = template_with_name[arg]
      elseif arg ~= "" then
        return false,
          ("[snippet-converter.nvim] unknown template name '%s'; must be one of %s"):format(
            arg,
            table.concat(template_names, ", ")
          )
      end
    end
  end
  if #templates == 0 then
    templates = config.templates
  end
  return true, {
    templates = templates,
    opts = opts,
  }
end

return M

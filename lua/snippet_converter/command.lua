local M = {}

local CmdOpts = {
  headless = 1,
}

---@return boolean ok
---@return table | string templates and opts table or error message
M.validate_args = function(args, config)
  local templates = {}
  local opts = {}
  local template_with_name = {}
  local template_names = {}
  for i, template in ipairs(config.templates) do
    template_with_name[template.name] = true
    template_names[i] = template.name
  end

  for i, arg in ipairs(args) do
    if arg:sub(1, 2) == "--" then
      if not CmdOpts[arg:sub(3)] then
        return false, ("[snippet-converter.nvim] unknown option '%s'"):format(arg)
      end
      opts[arg] = true
    else
      if not template_with_name[arg] then
        return false,
          ("[snippet-converter.nvim] unknown template name '%s'; must be one of %s"):format(
            arg,
            table.concat(template_names, ", ")
          )
      else
        templates[#templates + 1] = config.templates[i]
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

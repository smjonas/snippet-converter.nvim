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
    template_with_name[template.name] = template
    template_names[i] = template.name
  end

  for _, arg in ipairs(args) do
    if arg:sub(1, 2) == "--" then
      local opt = arg:sub(3)
      if not CmdOpts[opt] then
        return false, ("[snippet-converter.nvim] unknown option '%s'"):format(arg)
      end
      opts[opt] = true
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

local display = require("snippet_converter.ui.display")

local View = {}

View.new = function()
  local self = {
    _window = display.new_window(),
  }
  local global_keymaps = {
    ["q"] = function()
      self._window.close()
    end,
    ["<Esc>"] = function()
      self._window.close()
    end,
  }
  display.register_global_keymaps(global_keymaps)
  return setmetatable(self, { __index = View })
end

function View:open()
  self._window.open()
end

function View:destroy()
  self._window.close()
  self._window = nil
end

function View:draw(model)
  print("Draw")
  print(vim.inspect(model))
  local lines = {}
  local pos = 1
  for _, task in ipairs(model.tasks) do
    lines[pos] = task.source_format
    lines[pos + 1] = ("Found %s snippets in %s files."):format(task.num_snippets, task.num_files)
    pos = pos + 2
  end
  print(vim.inspect(lines))
  self._window.draw({
    lines = lines,
  })
end

return View

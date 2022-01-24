local view = require("snippet_converter.ui.view")

local window = view.new_window()
window.open()

view.register_keymap("q", function()
  window.close()
end)

view.register_keymap("<Esc>", function()
  window.close()
end)

window.draw({
  lines = {
    "a", "b", "c"
  }
})

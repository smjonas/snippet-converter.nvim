local display = require("snippet_converter.ui.display")
local Node = require("snippet_converter.ui.node")
local TaskState = require("snippet_converter.ui.task_state")

local View = {}

View.new = function()
  local self = {
    _window = display.new_window(),
  }
  local global_keymaps = {
    ["q"] = self._window.close,
    ["<Esc>"] = self._window.close,
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
  self.state = nil
end

local create_node_for_task = function(view, model, task)
  local task_node = view.state.task_nodes[task.source_format]
  -- Create new task only if it has not been persisted across redraws
  if not task_node then
    local texts = {
      "> " .. task.source_format,
      (": successfully converted %s / %s snippets"):format(task.num_snippets, task.num_files),
    }
    task_node = Node.ExpandableNode(
      Node.MultiHlTextNode(texts, { "Comment", "Comment" }, Node.Style.LEFT_PADDING),
      Node.HlTextNode("test", "Comment")
    )
    view.state.task_nodes[task.source_format] = task_node
  end

  return Node.KeymapNode(task_node, "<cr>", function()
    task_node.is_expanded = not task_node.is_expanded
    -- Redraw view as the has layout changed
    view:draw(model, true)
  end)
end

function View:draw(model, persist_view_state)
  if not persist_view_state then
    self.state = {
      task_nodes = {},
    }
  end
  local header_title = Node.HlTextNode("snippet-converter.nvim", "Title", Node.Style.CENTERED)
  local header_url = Node.HlTextNode(
    "https://github.com/smjonas/snippet-converter.nvim",
    "Comment",
    Node.Style.CENTERED
  )
  local nodes = { header_title, header_url, Node.NewLine() }
  for _, task in ipairs(model.tasks) do
    nodes[#nodes + 1] = create_node_for_task(self, model, task)
  end
  self._window.draw(Node.RootNode(nodes))
end

return View

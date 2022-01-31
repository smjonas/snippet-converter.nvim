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

local create_task_node = {
  [TaskState.CONVERSION_STARTED] = function(task, source_format, _, _)
    local texts = {
      source_format,
      ": converting snippets... (found ",
      tostring(task.num_snippets),
      " snippets in",
      tostring(task.num_input_files),
      " input files)",
    }
    return Node.MultiHlTextNode(texts, { "Statement", "", "Special", "", "Special", "" })
  end,
  [TaskState.CONVERSION_COMPLETED] = function(task, source_format, view, model)
    local node_icons = {
      [false] = "  ",
      [true] = "  ",
    }
    local texts = {
      node_icons[false],
      source_format,
      ": successfully converted ",
      tostring(task.num_snippets - #task.failures),
      " / ",
      tostring(task.num_snippets),
      " snippets",
      " (",
      tostring(task.num_input_files),
      " input files)",
    }
    local task_node = Node.ExpandableNode(
      Node.MultiHlTextNode(
        texts,
        { "", "Statement", "", "Special", "", "Special", "", "Comment", "Comment", "Comment" }
      ),
      Node.HlTextNode("test", "Comment")
    )
    return Node.KeymapNode(task_node, "<cr>", function()
      task_node.is_expanded = not task_node.is_expanded
      texts[1] = node_icons[task_node.is_expanded]
      -- Redraw view as the has layout changed
      view:draw(model, true)
    end)
  end,
}

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
  for source_format, task in pairs(model.tasks) do
    local task_node = self.state.task_nodes[source_format]
    -- Create new task only if it has not been persisted across redraws
    if not task_node then
      task_node = create_task_node[task.state](task, source_format, self, model)
      self.state.task_nodes[source_format] = task_node
    end
    nodes[#nodes + 1] = task_node
  end
  self._window.draw(Node.RootNode(nodes))
end

return View

local display = require("snippet_converter.ui.display")
local Node = require("snippet_converter.ui.node")

local View = {}

View.new = function(settings)
  local self = {
    settings = settings or {},
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

function View:get_node_icons(is_expanded)
  if self.settings.use_nerdfont_icons then
    if is_expanded then
      return "  "
    else
      return "  "
    end
  else
    if is_expanded then
      return " \\ "
    else
      return " > "
    end
  end
end

local amount_to_files_string = function(amount)
  if amount == 1 then
    return "file"
  else
    return "files"
  end
end

local create_failure_node = function(failures, num_failures, view)
  local texts = {
    view:get_node_icons(false),
    tostring(num_failures) .. " snippets could not be converted. ",
    "Press enter to view details",
  }
  local failure_nodes = { Node.NewLine() }
  for i, failure in ipairs(failures) do
    local detail_texts = {
      ("%s:%s ("):format(failure.snippet.path, failure.snippet.line_nr),
      failure.snippet.trigger,
      ("): %s"):format(failure.msg),
    }
    failure_nodes[i + 1] = Node.MultiHlTextNode(detail_texts, {
      "",
      "Special",
      "",
    }, Node.Style.LeftTruncated(5))
  end
  return Node.ExpandableNode(
    Node.MultiHlTextNode(texts, { "", "", "Comment" }, Node.Style.Padding(4)),
    Node.RootNode(failure_nodes),
    function(is_expanded)
      texts[1] = view:get_node_icons(is_expanded)
      -- Redraw view as the layout has changed
      view:draw(view.model, true)
    end
  )
end

local create_task_node = function(task, source_format, view)
  local texts = {
    view:get_node_icons(true),
    source_format,
    ": successfully converted ",
    tostring(task.num_snippets - view.model.max_num_failures),
    " / ",
    tostring(task.num_snippets),
    " snippets ",
    ("(%s input %s)"):format(tostring(task.num_input_files), amount_to_files_string(task.num_input_files)),
  }
  local child_nodes = {}
  for target_format, failures in pairs(task.converter_errors) do
    local num_failures = #failures
    local num_output_files = task.num_output_files[target_format]
    local success_texts = {
      "- ",
      source_format,
      " -> ",
      target_format,
      (" (%d output %s)"):format(num_output_files, amount_to_files_string(num_output_files)),
    }
    local failure_node
    if num_failures > 0 then
      failure_node = create_failure_node(failures, num_failures, view)
    end
    child_nodes[#child_nodes + 1] = Node.RootNode {
      Node.MultiHlTextNode(
        success_texts,
        { "", "Statement", "", "Statement", "Comment" },
        Node.Style.Padding(3)
      ),
      failure_node,
    }
  end
  return Node.ExpandableNode(
    Node.MultiHlTextNode(texts, { "", "Statement", "", "Special", "", "Special", "", "Comment" }),
    Node.RootNode(child_nodes),
    function(is_expanded)
      texts[1] = view:get_node_icons(is_expanded)
      -- Redraw view as the has layout changed
      view:draw(view.model, true)
    end,
    true
  )
end

local header_nodes
local get_header_node = function(is_converting)
  if not header_nodes then
    local header_title = Node.HlTextNode("snippet-converter.nvim", "Title", Node.Style.Centered())
    local header_url = Node.HlTextNode(
      "https://github.com/smjonas/snippet-converter.nvim",
      "Comment",
      Node.Style.Centered()
    )
    header_nodes = { header_title, header_url, Node.NewLine() }
  end
  if is_converting then
    header_nodes[4] = Node.HlTextNode("  Converting snippets...", "")
  else
    table.remove(header_nodes)
  end
  return header_nodes
end

function View:draw(model, persist_view_state, is_converting)
  if not persist_view_state then
    self.state = {
      task_nodes = {},
    }
  end
  self.model = model
  local nodes = get_header_node(is_converting)
  for source_format, task in pairs(model.tasks or {}) do
    local task_node = self.state.task_nodes[source_format]
    -- Create new task only if it has not been persisted across redraws
    if not task_node then
      task_node = create_task_node(task, source_format, self)
      self.state.task_nodes[source_format] = task_node
    end
    nodes[#nodes + 1] = task_node
  end
  self._window.draw(Node.RootNode(nodes))
end

return View

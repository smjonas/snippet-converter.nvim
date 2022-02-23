local display = require("snippet_converter.ui.display")
local Node = require("snippet_converter.ui.node")

local View = {}

local Scene = {
  Main = 1,
  Help = 2,
}

View.new = function(settings)
  local self = {
    settings = settings or {},
    _window = display.new_window(),
    current_scene = Scene.Main,
  }
  local global_keymaps = {
    ["q"] = self._window.close,
    ["<esc>"] = self._window.close,
    ["?"] = function()
      self:toggle_help()
    end,
    ["<c-q>"] = function()
      -- no-op: disable potential user keymap to avoid issues
      -- when <c-q> is remapped to toggle the quickfix list
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
  self.state = nil
end

function View:toggle_help()
  self.current_scene = self.current_scene == Scene.Main and Scene.Help or Scene.Main
  self:draw(self.model, true)
end

function View:get_node_icon(is_expanded)
  if self.settings.ui.use_nerdfont_icons then
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

local show_failures_in_qflist = function(failures)
  local qf_entries = {}
  for i, failure in ipairs(failures) do
    qf_entries[i] = {
      filename = vim.fn.expand(failure.snippet.path),
      lnum = failure.snippet.line_nr,
      text = failure.msg,
    }
  end
  vim.fn.setqflist(qf_entries, "r")
  vim.cmd("copen")
end

function View:create_failure_node(failures, num_failures)
  local texts = {
    self:get_node_icon(false),
    ("%d snippets could not be converted:"):format(num_failures),
  }
  local open_qflist_callback = function()
    self._window.close()
    show_failures_in_qflist(failures)
  end
  local failure_nodes = { Node.KeymapNode(Node.NewLine(), "<c-q>", open_qflist_callback) }
  for i, failure in ipairs(failures) do
    local detail_texts = {
      ("%s:%s ("):format(failure.snippet.path, failure.snippet.line_nr),
      failure.snippet.trigger,
      ("): %s"):format(failure.msg),
    }
    local failure_node = Node.MultiHlTextNode(detail_texts, {
      "",
      "Special",
      "",
    }, Node.Style.LeftTruncated(5))
    failure_nodes[i + 1] = Node.KeymapNode(failure_node, "<c-q>", open_qflist_callback)
  end
  return Node.ExpandableNode(
    Node.KeymapNode(
      Node.MultiHlTextNode(texts, { "", "" }, Node.Style.Padding(4)),
      "<c-q>",
      open_qflist_callback
    ),
    Node.RootNode(failure_nodes),
    function(is_expanded)
      texts[1] = self:get_node_icon(is_expanded)
      -- Redraw view as the layout has changed
      self:draw(self.model, true)
    end
  )
end

local header_nodes = {}
function View:get_header_nodes(scene, is_converting)
  if not header_nodes[scene] then
    local header_title = Node.HlTextNode("snippet-converter.nvim", "Title", Node.Style.Centered())
    local header_url = Node.HlTextNode(
      "https://github.com/smjonas/snippet-converter.nvim",
      "Comment",
      Node.Style.Centered()
    )
    local header_text = scene == Scene.Main and " to view keyboard shortcuts" or " to go back"
    local header_toggle_keymaps = Node.MultiHlTextNode(
      { "Press ", "?", header_text },
      { "Comment", "Title", "Comment" },
      Node.Style.Centered()
    )
    header_nodes[scene] = {
      header_title,
      header_url,
      header_toggle_keymaps,
      Node.NewLine(),
    }
  end
  header_nodes[scene][5] = is_converting and Node.HlTextNode("  Converting snippets...", "") or nil
  return header_nodes[scene]
end

function View:create_task_node(task, source_format)
  local texts = {
    self:get_node_icon(true),
    source_format,
    ": successfully converted ",
    tostring(task.num_snippets - self.model.max_num_failures),
    " / ",
    tostring(task.num_snippets),
    " snippets ",
    ("(%s input %s)"):format(
      tostring(task.num_input_files),
      amount_to_files_string(task.num_input_files)
    ),
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
      failure_node = self:create_failure_node(failures, num_failures)
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
      texts[1] = self:get_node_icon(is_expanded)
      -- Redraw view as the has layout changed
      self:draw(self.model, true)
    end,
    true
  )
end

function View:create_skipped_task_node(reason, source_format)
  local text
  if reason == self.model.Reason.NO_INPUT_FILES then
    text = "No input files found"
  elseif reason == self.model.Reason.NO_INPUT_SNIPPETS then
    text = "No valid input snippets found"
  end
  return Node.MultiHlTextNode(
    { source_format, " - ", text },
    { "Statement", "", "Error" },
    Node.Style.Padding(2)
  )
end

function View:create_task_nodes(scene)
  local nodes = self:get_header_nodes(self.current_scene, self.model.is_converting)
  if scene == Scene.Main then
    for source_format, reason in pairs(self.model.skipped_tasks) do
      nodes[#nodes + 1] = self:create_skipped_task_node(reason, source_format)
    end
    for source_format, task in pairs(self.model.tasks) do
      local task_node = self.state.task_nodes[source_format]
      -- Create new task only if it has not been persisted across redraws
      if not task_node then
        task_node = self:create_task_node(task, source_format)
        self.state.task_nodes[source_format] = task_node
      end
      nodes[#nodes + 1] = task_node
    end
  elseif scene == Scene.Help then
    local expand_node = Node.MultiHlTextNode({
      "<cr> (enter)",
      ("  toggle a%snode"):format(self:get_node_icon(false)),
    }, { "Statement", "" }, Node.Style.Padding(2))
    local qflist_node = Node.MultiHlTextNode({
      "<c-q>",
      "         send the errors under the cursor to the quickfix list and close the window",
    }, { "Statement", "" }, Node.Style.Padding(2))
    local close_node = Node.MultiHlTextNode(
      { "<esc> / q", "     close this window" },
      { "Statement", "" },
      Node.Style.Padding(2)
    )
    nodes[#nodes + 1] = Node.RootNode { expand_node, qflist_node, close_node }
  end
  return nodes
end

function View:draw(model, persist_view_state)
  self.model = model
  if not persist_view_state then
    self.state = {
      task_nodes = {},
    }
  end
  local nodes = self:create_task_nodes(self.current_scene)
  self._window.draw(Node.RootNode(nodes))
end

return View

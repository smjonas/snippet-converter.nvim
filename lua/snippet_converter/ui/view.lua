local display = require("snippet_converter.ui.display")
local Node = require("snippet_converter.ui.node")
local Model = require("snippet_converter.ui.model")

---@class View
---@field settings table
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
    ["?"] = function()
      self:toggle_help()
    end,
    ["q"] = self._window.close,
    ["<esc>"] = self._window.close,
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
end

function View:toggle_help()
  self.current_scene = self.current_scene == Scene.Main and Scene.Help or Scene.Main
  self:draw(self.model, false)
end

function View:get_node_icon(is_expanded)
  if self.settings.ui.use_nerdfont_icons then
    return is_expanded and "  " or "  "
  else
    return is_expanded and " \\ " or " > "
  end
end

function View:get_arrow_icon()
  return self.settings.ui.use_nerdfont_icons and "→" or "->"
end

function View:get_status_node_icon(status)
  local use_nerdfont = self.settings.ui.use_nerdfont_icons
  local icon = use_nerdfont and " " or "◍ "
  local hl_group
  if status == Model.Status.Error then
    hl_group = "healthError"
  elseif status == Model.Status.Warning then
    hl_group = "healthWarning"
  else
    hl_group = "healthSuccess"
  end
  return {
    icon = icon,
    hl_group = hl_group,
  }
end

local amount_to_files_string = function(amount)
  return amount == 1 and "file" or "files"
end

local amount_to_snippets_string = function(amount)
  return amount == 1 and "snippet" or "snippets"
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

function View:create_failure_nodes(failures)
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
    }, Node.Style.LeftTruncated(7))
    failure_nodes[i + 1] = Node.KeymapNode(failure_node, "<c-q>", open_qflist_callback)
  end
  return failure_nodes
end

function View:get_header_nodes(scene, is_converting)
  local header_nodes = {}
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
  if is_converting then
    header_nodes[scene][5] = Node.HlTextNode("  Converting snippets...", "")
  elseif header_nodes[scene][5] then
    table.remove(header_nodes[scene])
  end
  return header_nodes[scene]
end

function View:create_task_node(template, task, source_format)
  local model = self.model
  local max_status = model.tasks[template.name][source_format].max_conversion_status
  local status_icon = self:get_status_node_icon(max_status)
  local num_snippets_converted = task.num_snippets - task.num_failures

  local texts, highlights
  if max_status == model.Status.Error then
    texts = {
      self:get_node_icon(false),
      status_icon.icon,
      source_format,
      ": ",
      "no snippets converted ",
      ("(%s input %s)"):format(
        tostring(task.num_input_files),
        amount_to_files_string(task.num_input_files)
      ),
    }
    highlights = { "", status_icon.hl_group, "Statement", "", "healthError", "Comment" }
  else
    texts = {
      self:get_node_icon(false),
      status_icon.icon,
      source_format,
      num_snippets_converted > 0 and ": successfully converted " or ": converted ",
      tostring(num_snippets_converted),
      " / ",
      tostring(task.num_snippets),
      " snippets ",
      ("(%s input %s)"):format(
        tostring(task.num_input_files),
        amount_to_files_string(task.num_input_files)
      ),
    }
    highlights = {
      "",
      status_icon.hl_group,
      "Statement",
      "",
      "Special",
      "",
      "Special",
      "",
      "Comment",
    }
  end

  local child_nodes = {}
  for target_format, failures in pairs(task.converter_errors) do
    local num_output_files = task.num_output_files[target_format]

    local task_texts = {
      self:get_node_icon(false),
      source_format,
      self.settings.ui.use_nerdfont_icons and " → " or " -> ",
      target_format,
      (" (%d output %s)"):format(num_output_files, amount_to_files_string(num_output_files)),
    }

    local num_failures = #failures
    table.insert(
      task_texts,
      5,
      (": %d %s could not be converted"):format(
        num_failures,
        amount_to_snippets_string(num_failures)
      )
    )
    local failure_nodes = self:create_failure_nodes(failures)
    child_nodes[#child_nodes + 1] = Node.ExpandableNode(
      Node.MultiHlTextNode(
        task_texts,
        { "", "Statement", "", "Statement", "", "Comment" },
        Node.Style.Padding(4)
      ),
      Node.RootNode(failure_nodes),
      function(is_expanded)
        task_texts[1] = self:get_node_icon(is_expanded)
        -- Redraw view as the has layout changed
        self:draw(model, true)
      end,
      false
    )
    -- TODO: successful conversions
    -- child_nodes[#child_nodes + 1] = Node.MultiHlTextNode(
    --   task_texts,
    --   { status_icon.hl_group, "Statement", "", "Statement", "Comment" },
    --   Node.Style.Padding(5)
    -- )
  end

  return Node.ExpandableNode(
    Node.MultiHlTextNode(texts, highlights, Node.Style.Padding(2)),
    Node.RootNode(child_nodes),
    function(is_expanded)
      texts[1] = self:get_node_icon(is_expanded)
      -- Redraw view as the has layout changed
      self:draw(model, true)
    end,
    false
  )
end

function View:create_skipped_task_node(reason, source_format)
  local text
  if reason == self.model.Reason.NO_INPUT_FILES then
    text = "no matching input files found"
  elseif reason == self.model.Reason.NO_INPUT_SNIPPETS then
    text = "no valid input snippets found"
  end
  local status = self:get_status_node_icon(self.model.Status.Error)
  return Node.MultiHlTextNode(
    { "- ", status.icon, source_format, ": ", text },
    { "", status.hl_group, "Statement", "", "healthError" },
    Node.Style.Padding(3)
  )
end

function View:create_task_nodes(scene)
  local model = self.model
  local nodes = self:get_header_nodes(self.current_scene, model.is_converting)
  if scene == Scene.Main then
    for name, template in pairs(model.templates) do
      local template_nodes = {}
      for source_format, reason in pairs(model.skipped_tasks[name] or {}) do
        template_nodes[#template_nodes + 1] = self:create_skipped_task_node(reason, source_format)
      end
      for source_format, task in pairs(model.tasks[name] or {}) do
        template_nodes[#template_nodes + 1] = self:create_task_node(template, task, source_format)
      end
      -- TODO: show max status of tasks, auto-expand only for yellow / red tasks
      -- TODO: write number of converted snippets after Template header
      local template_title_texts = { self:get_node_icon(true), "Template " .. name }
      nodes[#nodes + 1] = Node.ExpandableNode(
        Node.MultiHlTextNode(template_title_texts, { "", "" }),
        Node.RootNode(template_nodes),
        function(is_expanded)
          template_title_texts[1] = self:get_node_icon(is_expanded)
          self:draw(self.model, true)
        end,
        true
      )
      -- Add separator
      nodes[#nodes + 1] = Node.NewLine()
    end
  elseif scene == Scene.Help then
    local expand_node = Node.MultiHlTextNode({
      "<cr> (enter)",
      ("  toggle a%snode"):format(self:get_node_icon(false)),
    }, { "Statement", "" }, Node.Style.Padding(2))
    local open_node = Node.MultiHlTextNode(
      { "o", "             open the snippet under the cursor in a new split" },
      { "Statement", "" },
      Node.Style.Padding(2)
    )
    local qflist_node = Node.MultiHlTextNode({
      "<c-q>",
      "         send the errors under the cursor to the quickfix list and close this window",
    }, { "Statement", "" }, Node.Style.Padding(2))
    local close_node = Node.MultiHlTextNode(
      { "<esc> / q", "     close this window" },
      { "Statement", "" },
      Node.Style.Padding(2)
    )
    nodes[#nodes + 1] = Node.RootNode { expand_node, open_node, qflist_node, close_node }
  end
  return nodes
end

function View:draw(model, persist_view_state)
  self.model = model
  if not persist_view_state then
    -- TODO: persist across scene changes
    self.persisted_nodes = self:create_task_nodes(self.current_scene)
  end
  self._window.draw(Node.RootNode(self.persisted_nodes))
end

return View

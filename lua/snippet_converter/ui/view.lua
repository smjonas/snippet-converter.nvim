local display = require("snippet_converter.ui.display")
local Node = require("snippet_converter.ui.node")
local Model = require("snippet_converter.ui.model")
local tbl = require("snippet_converter.utils.table")

---@class View
---@field settings table
---@field persisted_nodes table
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
    persisted_nodes = {
      [Scene.Main] = {},
      [Scene.Help] = {},
    },
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
    ["<c-i>"] = function()
      self._window.close()
      self:show_input_paths_in_qflist()
    end,
    ["<c-o>"] = function()
      self._window.close()
      self:show_output_paths_in_qflist()
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
  -- Persist the previous nodes when switching to the help scene so expanded items stay expanded
  if self.current_scene == Scene.Help then
    self.persisted_nodes[self.current_scene] = self:create_task_nodes(self.current_scene)
  end
  self:draw(self.model, false)
end

function View:get_node_icon(is_expanded)
  if self.settings.ui.use_nerdfont_icons then
    return is_expanded and " " or " "
  else
    return is_expanded and "\\ " or "> "
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

local files_string_from_amount = function(amount)
  return amount == 1 and "file" or "files"
end

local amount_to_snippets_string = function(amount)
  return amount == 1 and "snippet" or "snippets"
end

local show_files_in_qflist = function(files, qf_title)
  local qf_entries = {}
  for i, file in ipairs(files) do
    qf_entries[i] = {
      filename = vim.fn.expand(file.path),
      lnum = 1,
      text = ("%s (%s)"):format(vim.fn.fnamemodify(file.path, ":t"), file.format),
    }
  end
  vim.fn.setqflist({}, "r", {
    items = qf_entries,
    title = qf_title,
  })
  vim.cmd("copen")
end

function View:show_input_paths_in_qflist()
  show_files_in_qflist(self.model.input_files, "Snippet input paths")
end

function View:show_output_paths_in_qflist()
  show_files_in_qflist(self.model.output_files, "Snippet output paths")
end

local show_failures_in_qflist = function(failures, source_format, target_format, start_idx)
  local qf_entries = {}
  for i, failure in ipairs(failures) do
    qf_entries[i] = {
      filename = vim.fn.expand(failure.snippet.path),
      lnum = failure.snippet.line_nr,
      text = failure.msg,
    }
  end
  vim.fn.setqflist({}, "r", {
    items = qf_entries,
    idx = start_idx,
    title = ("%s -> %s conversion"):format(source_format, target_format),
  })
  vim.cmd("copen")
end

function View:create_failure_nodes(failures, source_format, target_format)
  local open_qflist_callback = function()
    self._window.close()
    show_failures_in_qflist(failures, source_format, target_format)
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
    open_qflist_callback = function()
      self._window.close()
      show_failures_in_qflist(failures, source_format, target_format, i)
    end
    failure_nodes[i + 1] = Node.KeymapNode(failure_node, "<c-q>", open_qflist_callback)
  end
  return failure_nodes
end

function View:get_header_nodes(scene, is_converting)
  local header_nodes = {}
  local header_title = Node.HlTextNode("snippet-converter.nvim", "Title", Node.Style.Centered())
  local header_url =
    Node.HlTextNode("https://github.com/smjonas/snippet-converter.nvim", "Comment", Node.Style.Centered())
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
        files_string_from_amount(task.num_input_files)
      ),
    }
    highlights = { "", status_icon.hl_group, "Statement", "", "healthError", "Comment" }
  else
    texts = {
      status_icon.icon,
      source_format,
      num_snippets_converted > 0 and ": successfully converted " or ": converted ",
      tostring(num_snippets_converted),
      " / ",
      tostring(task.num_snippets),
      " snippets ",
      ("(%s input %s)"):format(
        tostring(task.num_input_files),
        files_string_from_amount(task.num_input_files)
      ),
    }
    highlights = {
      status_icon.hl_group,
      "Statement",
      "",
      "Special",
      "",
      "Special",
      "",
      "Comment",
    }
    if max_status == model.Status.Success then
      return Node.MultiHlTextNode(texts, highlights, Node.Style.Padding(3))
    end
  end

  -- max_status == Status.Warning
  table.insert(texts, 2, self:get_node_icon(false))
  table.insert(highlights, 2, "")
  local child_nodes = {}
  for target_format, failures in pairs(task.converter_errors) do
    local num_output_dirs = #task.output_dirs[target_format]

    local task_texts = {
      self:get_node_icon(false),
      source_format,
      self.settings.ui.use_nerdfont_icons and " → " or " -> ",
      target_format,
      (" (%d output %s)"):format(num_output_dirs, files_string_from_amount(num_output_dirs)),
    }

    local num_failures = #failures
    table.insert(
      task_texts,
      5,
      (": %d %s could not be converted"):format(num_failures, amount_to_snippets_string(num_failures))
    )
    local failure_nodes = self:create_failure_nodes(failures, source_format, target_format)
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
        self:draw(model, false)
      end,
      false
    )
  end

  return Node.ExpandableNode(
    Node.MultiHlTextNode(texts, highlights, Node.Style.Padding(3)),
    Node.RootNode(child_nodes),
    function(is_expanded)
      texts[2] = self:get_node_icon(is_expanded)
      -- Redraw view as the has layout changed
      self:draw(model, false)
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
    { status.icon, source_format, ": ", text },
    { status.hl_group, "Statement", "", "healthError" },
    Node.Style.Padding(3)
  )
end

function View:get_help_scene_nodes()
  if self._help_scene_nodes then
    return self._help_scene_nodes
  end
  local expand_node = Node.MultiHlTextNode({
    "<cr> (enter)",
    ("  Toggle a %snode."):format(self:get_node_icon(false)),
  }, { "Statement", "" }, Node.Style.Padding(2))

  local errors_to_qflist_node = Node.MultiHlTextNode({
    "<c-q>",
    "         Send the errors under the cursor to the quickfix list.",
  }, { "Statement", "" }, Node.Style.Padding(2))

  local input_to_qflist_node = Node.MultiHlTextNode({
    "<c-i>",
    "         Send all input files to the quickfix list.",
  }, { "Statement", "" }, Node.Style.Padding(2))

  local output_to_qflist_node = Node.MultiHlTextNode({
    "<c-o>",
    "         Send all output files to the quickfix list.",
  }, { "Statement", "" }, Node.Style.Padding(2))

  local close_node = Node.MultiHlTextNode(
    { "<esc> / q", "     Close this window." },
    { "Statement", "" },
    Node.Style.Padding(2)
  )

  self._help_scene_nodes = Node.RootNode {
    expand_node,
    errors_to_qflist_node,
    input_to_qflist_node,
    output_to_qflist_node,
    close_node,
  }
  return self._help_scene_nodes
end

function View:create_task_nodes(scene)
  local model = self.model
  local nodes = self:get_header_nodes(self.current_scene, model.is_converting)
  if scene == Scene.Main then
    for name, template in tbl.pairs_by_keys(model.templates) do
      local template_nodes = {}
      for source_format, reason in pairs(model.skipped_tasks[name] or {}) do
        template_nodes[#template_nodes + 1] = self:create_skipped_task_node(reason, source_format)
      end
      for source_format, task in tbl.pairs_by_keys(model.tasks[name] or {}) do
        template_nodes[#template_nodes + 1] = self:create_task_node(template, task, source_format)
      end

      local amount_string = model.total_num_snippets == 1 and "snippet" or "snippets"
      local template_title_texts = {
        self:get_node_icon(true),
        "Template " .. name,
        (" (%d %s converted)"):format(model.total_num_snippets - model.total_num_failures, amount_string),
      }
      nodes[#nodes + 1] = Node.ExpandableNode(
        Node.MultiHlTextNode(template_title_texts, { "", "", "Comment" }, Node.Style.Padding(1)),
        Node.RootNode(template_nodes),
        function(is_expanded)
          template_title_texts[1] = self:get_node_icon(is_expanded)
          self:draw(self.model, false)
        end,
        true
      )
      -- Add separator
      nodes[#nodes + 1] = Node.NewLine()
    end
  elseif scene == Scene.Help then
    nodes[#nodes + 1] = self:get_help_scene_nodes()
  end
  return nodes
end

function View:draw(model, do_redraw)
  self.model = model
  if do_redraw then
    -- Redraw the scene from scratch
    self.persisted_nodes[self.current_scene] = self:create_task_nodes(self.current_scene)
  end
  self._window.draw(Node.RootNode(self.persisted_nodes[self.current_scene]))
end

return View

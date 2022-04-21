local Node = require("snippet_converter.ui.node")

local M = {}

local global_keymaps, line_keymaps

M.register_global_keymaps = function(keymaps)
  global_keymaps = keymaps
end

local from_hex = function(str)
  return (str:gsub("..", function(x)
    return string.char(tonumber(x, 16))
  end))
end

local to_hex = function(str)
  return (str:gsub(".", function(x)
    return string.format("%02X", string.byte(x))
  end))
end

M.handle_keymap = function(hex_lhs)
  local lhs = from_hex(hex_lhs)
  global_keymaps[lhs]()
end

M.handle_line_keymap = function(win_id, hex_lhs)
  local line = vim.api.nvim_win_get_cursor(win_id)[1]
  local lhs = from_hex(hex_lhs)
  if line_keymaps[line] and line_keymaps[line][lhs] then
    line_keymaps[line][lhs]()
  end
end

local create_popup_window_opts = function()
  local win_width = vim.o.columns
  local win_height = vim.o.lines - vim.o.cmdheight - 2 -- Add margin for status and buffer lines
  local popup_window = {
    relative = "editor",
    width = math.floor(win_width * 0.7),
    height = math.floor(win_height * 0.7),
    style = "minimal",
    border = "rounded",
  }
  popup_window.col = math.floor((win_width - popup_window.width) / 2)
  popup_window.row = math.floor((win_height - popup_window.height) / 2)
  return popup_window
end

local apply_style = function(window, text, style)
  if style.type == Node.Style.CENTERED then
    local padding = math.floor((window.width - #text) / 2)
    return (" "):rep(math.max(0, padding)) .. text
  elseif style.type == Node.Style.PADDING then
    return (" "):rep(style.padding) .. text
  elseif style.type == Node.Style.LEFT_TRUNCATED then
    local max_width = window.width - style.padding - 2 -- Add 2 cells wide right margin
    if #text > max_width then
      text = "..." .. text:sub((#text - max_width + 1) + 3)
    end
    return (" "):rep(style.padding) .. text
  end
end

-- TODO: redraw
local render_node
render_node = {
  [Node.Type.ROOT] = function(window, node, out)
    for _, child_node in ipairs(node.child_nodes) do
      render_node[child_node.type](window, child_node, out)
    end
  end,
  [Node.Type.HL_TEXT] = function(window, node, out)
    local line
    if node.style then
      line = apply_style(window, node.text, node.style)
    else
      line = node.text
    end
    local line_idx = #out.lines
    out.lines[line_idx + 1] = line
    out.highlights[#out.highlights + 1] = {
      hl_group = node.hl_group,
      line = line_idx,
      col_start = 0,
      col_end = #line,
    }
  end,
  [Node.Type.MULTI_HL_TEXT] = function(window, node, out)
    local merged_line = table.concat(node.texts)
    local col_offset = 0
    if node.style then
      local merged_line_styled = apply_style(window, merged_line, node.style)
      -- Assumes that apply_style only adds text from the left of the line
      col_offset = #merged_line_styled - #merged_line
      merged_line = merged_line_styled
    end
    local line_idx = #out.lines
    out.lines[line_idx + 1] = merged_line
    for i, hl_group in ipairs(node.hl_groups) do
      local text_len = #node.texts[i]
      if col_offset >= 0 then
        -- Ignore empty highlight groups
        if hl_group ~= "" then
          out.highlights[#out.highlights + 1] = {
            hl_group = hl_group,
            line = line_idx,
            col_start = col_offset,
            col_end = col_offset + text_len,
          }
        end
      end
      col_offset = col_offset + text_len
    end
  end,
  [Node.Type.EXPANDABLE] = function(window, node, out)
    render_node[node.parent_node.type](window, node.parent_node, out)
    if node.is_expanded then
      render_node[node.child_node.type](window, node.child_node, out)
    end
  end,
  [Node.Type.KEYMAP] = function(window, node, out)
    local parent_line = #out.lines + 1
    render_node[node.node.type](window, node.node, out)
    out.line_keymaps[parent_line] = node.keymap
  end,
  [Node.Type.NEW_LINE] = function(_, _, out)
    out.lines[#out.lines + 1] = ""
  end,
}

local function set_keymap(bufnr, lhs, cmd_string)
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    lhs,
    -- Convert to hex value to avoid issues with the lhs of the keymap being
    -- interpreted literally by Neovim.
    cmd_string:format(to_hex(lhs)),
    { nowait = true, silent = true, noremap = true }
  )
end

M.new_window = function()
  local namespace_id = vim.api.nvim_create_namespace("snippet_converter")
  local augroup_id = vim.api.nvim_create_augroup("SnippetConverterWindow", {})
  local win_id, bufnr

  local function open()
    bufnr = vim.api.nvim_create_buf(false, true)
    win_id = vim.api.nvim_open_win(bufnr, true, create_popup_window_opts())

    local win_opts = {
      wrap = false,
      foldenable = false,
      cursorline = true,
    }

    local buf_opts = {
      modifiable = false,
      swapfile = false,
      buftype = "nofile",
      bufhidden = "wipe",
      filetype = "snippet_converter",
    }

    for key, value in pairs(win_opts) do
      vim.api.nvim_win_set_option(win_id, key, value)
    end

    for key, value in pairs(buf_opts) do
      vim.api.nvim_buf_set_option(bufnr, key, value)
    end

    -- Resize autocommand
    vim.api.nvim_create_autocmd("VimResized", {
      group = augroup_id,
      buffer = bufnr,
      callback = function()
        M.redraw_window(win_id)
      end,
    })

    -- Autoclose autocommand (closes window when clicked outside)
    vim.api.nvim_create_autocmd({ "WinLeave", "BufHidden", "BufLeave" }, {
      group = augroup_id,
      buffer = bufnr,
      once = true,
      callback = function()
        M.destroy_window(win_id, bufnr)
      end,
    })
  end

  local draw = function(node)
    local win_valid = win_id ~= nil and vim.api.nvim_win_is_valid(win_id)
    local buf_valid = bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
    if not win_valid or not buf_valid then
      print("Invalid window or buffer ID", win_id, bufnr)
      return
    end

    -- Set line contents
    local window = {
      width = vim.api.nvim_win_get_width(win_id),
    }
    local render_output = {
      lines = {},
      highlights = {},
      line_keymaps = {},
    }
    render_node[node.type](window, node, render_output)

    vim.api.nvim_buf_clear_namespace(bufnr, namespace_id, 0, -1)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, render_output.lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

    -- Set highlights
    for _, highlight in ipairs(render_output.highlights) do
      vim.api.nvim_buf_add_highlight(
        bufnr,
        namespace_id,
        highlight.hl_group,
        highlight.line,
        highlight.col_start,
        highlight.col_end
      )
    end

    -- Set global keymaps
    for lhs, _ in pairs(global_keymaps) do
      set_keymap(bufnr, lhs, "<cmd>lua require('snippet_converter.ui.display').handle_keymap(%q)<cr>")
    end

    -- Set line keymaps
    line_keymaps = {}
    for line = 1, #render_output.lines do
      local keymap = render_output.line_keymaps[line]
      if keymap then
        line_keymaps[line] = { [keymap.lhs] = keymap.callback }
        local cmd_string = ("<cmd>lua require('snippet_converter.ui.display').handle_line_keymap(%d"):format(
          win_id
        )
        set_keymap(bufnr, keymap.lhs, cmd_string .. ",%q)<cr>")
      end
    end
  end

  local close = function()
    M.destroy_window(win_id, bufnr)
  end

  return {
    open = open,
    draw = draw,
    close = close,
  }
end

M.redraw_window = function(win_id)
  if vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_set_config(win_id, create_popup_window_opts())
  end
end

M.destroy_window = function(win_id, bufnr)
  if vim.api.nvim_win_is_valid(win_id) then
    vim.api.nvim_win_close(win_id, true)
  end

  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

return M

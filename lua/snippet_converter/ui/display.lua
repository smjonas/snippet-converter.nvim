local M = {}

local global_keymaps = {}
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

M.new_window = function()
  -- local namespace = vim.api.nvim_create_namespace("snippet_converter")

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

    local resize_autocmd = (
      "autocmd VimResized <buffer> lua require('snippet_converter.ui.display').redraw_window(%d)"
    ):format(win_id)

    -- Will close the window when clicked outside
    local autoclose_autocmd = (
      "autocmd WinLeave,BufHidden,BufLeave <buffer> ++once lua require('snippet_converter.ui.display').destroy_window(%d, %d)"
    ):format(win_id, bufnr)

    vim.cmd(([[
      augroup SnippetConverterWindow
        autocmd!
        %s
        %s
      augroup end
    ]]):format(resize_autocmd, autoclose_autocmd))
  end

  local draw = function(context)
    local win_valid = win_id ~= nil and vim.api.nvim_win_is_valid(win_id)
    local buf_valid = bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr)
    if not win_valid or not buf_valid then
      print("Invalid window or buffer ID", win_id, bufnr)
      return
    end

    -- Set line contents
    local lines, highlights = context.lines, context.highlights
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

    -- Register keymaps
    for lhs, _ in pairs(global_keymaps) do
      vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        lhs,
        string.format(
          "<cmd>lua require('snippet_converter.ui.display').handle_keymap(%q)<cr>",
          -- Convert to hex value to avoid issues with the lhs of the keymap being
          -- interpreted literally by Neovim.
          to_hex(lhs)
        ),
        { nowait = true, silent = true, noremap = true }
      )
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

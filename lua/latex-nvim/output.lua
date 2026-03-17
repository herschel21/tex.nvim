-- latex-nvim/output.lua
-- Manages the compilation-output floating/split window

local M = {}

local _buf  = nil   -- output buffer handle
local _win  = nil   -- output window handle
local _lines = {}   -- buffered lines (kept so we can re-open)

-- ── Buffer management ─────────────────────────────────────────────────────────

local function ensure_buf()
  if _buf and vim.api.nvim_buf_is_valid(_buf) then return _buf end
  _buf = vim.api.nvim_create_buf(false, true)   -- unlisted, scratch
  vim.api.nvim_buf_set_name(_buf, "latex-nvim://output")
  vim.api.nvim_set_option_value("buftype",    "nofile",  { buf = _buf })
  vim.api.nvim_set_option_value("bufhidden",  "hide",    { buf = _buf })
  vim.api.nvim_set_option_value("swapfile",   false,     { buf = _buf })
  vim.api.nvim_set_option_value("filetype",   "latexlog",{ buf = _buf })
  return _buf
end

--- Append a single line to the output buffer.
function M.append(line)
  local b = ensure_buf()
  table.insert(_lines, line)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(b) then
      local n = vim.api.nvim_buf_line_count(b)
      vim.api.nvim_buf_set_lines(b, n, n, false, { line })
      -- Auto-scroll if the window is visible
      if _win and vim.api.nvim_win_is_valid(_win) then
        local new_n = vim.api.nvim_buf_line_count(b)
        vim.api.nvim_win_set_cursor(_win, { new_n, 0 })
      end
    end
  end)
end

--- Clear the output buffer.
function M.clear()
  _lines = {}
  local b = ensure_buf()
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(b) then
      vim.api.nvim_buf_set_lines(b, 0, -1, false, {})
    end
  end)
end

-- ── Window management ─────────────────────────────────────────────────────────

--- Open the output window (horizontal split at the bottom).
function M.show(cfg)
  cfg = cfg or require("latex-nvim").config
  if _win and vim.api.nvim_win_is_valid(_win) then return end

  local b = ensure_buf()
  -- Replay any already-buffered lines
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(b) then
      vim.api.nvim_buf_set_lines(b, 0, -1, false, _lines)
    end
  end)

  local height = cfg and cfg.output_win_height or 12
  vim.cmd("botright " .. height .. "split")
  _win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(_win, b)

  -- Window-local options
  vim.api.nvim_set_option_value("wrap",        false, { win = _win })
  vim.api.nvim_set_option_value("number",      false, { win = _win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = _win })
  vim.api.nvim_set_option_value("signcolumn",  "no",  { win = _win })

  -- Return focus to the previous window
  vim.cmd("wincmd p")
end

--- Hide the output window (keep the buffer).
function M.hide()
  if _win and vim.api.nvim_win_is_valid(_win) then
    vim.api.nvim_win_close(_win, false)
    _win = nil
  end
end

--- Toggle the output window.
function M.toggle(cfg)
  if _win and vim.api.nvim_win_is_valid(_win) then
    M.hide()
  else
    M.show(cfg)
  end
end

return M

-- latex-nvim/view.lua
-- Opens the compiled PDF with evince (or any configured viewer)

local M = {}

local util = require("latex-nvim.util")

-- Track open viewer PIDs so we don't open duplicates
local _viewers = {}   -- keyed by pdf path

--- Derive PDF path from a tex path, or use the current buffer.
local function resolve_pdf(cfg)
  -- If called with an explicit path, use it
  local tex = vim.b.latex_root or vim.api.nvim_buf_get_name(0)
  if tex == "" then
    util.err("No file in buffer")
    return nil
  end
  local pdf = tex:gsub("%.tex$", ".pdf")
  if vim.fn.filereadable(pdf) == 0 then
    util.err("PDF not found: " .. pdf .. "  (compile first)")
    return nil
  end
  return pdf
end

--- Open (or re-focus) the PDF viewer.
--- @param pdf_file string|nil  explicit PDF path; if nil, derived from buffer
--- @param cfg      table|nil   plugin config
function M.open(pdf_file, cfg)
  cfg = cfg or require("latex-nvim").config
  local pdf = pdf_file or resolve_pdf(cfg)
  if not pdf then return end

  -- If the viewer is already running for this PDF, do nothing
  local existing = _viewers[pdf]
  if existing then
    -- Check if the process is still alive
    local alive = vim.fn.jobwait({ existing }, 0)[1] == -1
    if alive then
      util.info("latex-nvim: viewer already open for " .. vim.fn.fnamemodify(pdf, ":t"))
      return
    end
  end

  local job = vim.fn.jobstart(
    { cfg.viewer, pdf },
    {
      detach    = true,   -- keep the viewer alive if Neovim closes
      on_exit   = function()
        _viewers[pdf] = nil
      end,
    }
  )

  if job <= 0 then
    util.err("latex-nvim: failed to open viewer '" .. cfg.viewer .. "'")
  else
    _viewers[pdf] = job
    util.info("latex-nvim: opening " .. vim.fn.fnamemodify(pdf, ":t") .. " in " .. cfg.viewer)
  end
end

--- Close all open viewer instances.
function M.close_all()
  for pdf, job in pairs(_viewers) do
    vim.fn.jobstop(job)
    _viewers[pdf] = nil
  end
end

return M

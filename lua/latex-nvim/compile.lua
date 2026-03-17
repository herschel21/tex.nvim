-- latex-nvim/compile.lua
-- Handles compilation via the user's `compile_latex` script

local M = {}

local output  = require("latex-nvim.output")
local view    = require("latex-nvim.view")
local util    = require("latex-nvim.util")

-- Active job handle
local _job_id = nil
local _config = nil

-- ── Helpers ──────────────────────────────────────────────────────────────────

--- Return the tex file to compile.
--- Prefers the "root file" if set (like VimTex), otherwise the current buffer.
local function get_tex_file()
  -- Allow the user to pin a root file with :LatexSetRoot
  if vim.b.latex_root then
    return vim.b.latex_root
  end
  local f = vim.api.nvim_buf_get_name(0)
  if f == "" then
    util.err("No file in current buffer")
    return nil
  end
  if not f:match("%.tex$") then
    util.err("Current file is not a .tex file")
    return nil
  end
  return f
end

--- Derive the expected PDF path from a tex file path.
local function pdf_path(tex_file)
  return tex_file:gsub("%.tex$", ".pdf")
end

-- ── Core compile logic ────────────────────────────────────────────────────────

function M.compile(on_success)
  local cfg = _config or require("latex-nvim").config
  local tex  = get_tex_file()
  if not tex then return end

  -- Kill any running job first
  M.stop()

  -- Save all tex buffers silently
  vim.cmd("silent! wall")

  local dir  = vim.fn.fnamemodify(tex, ":h")
  local file = vim.fn.fnamemodify(tex, ":t")

  output.clear()
  output.append("── latex-nvim: compiling " .. file .. " ──")
  output.append("Script : " .. cfg.compile_script)
  output.append("Dir    : " .. dir)
  output.append("")

  local stdout_lines = {}
  local stderr_lines = {}

  _job_id = vim.fn.jobstart(
    { cfg.compile_script, tex },
    {
      cwd        = dir,
      stdout_buffered = false,
      stderr_buffered = false,

      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then
            output.append(line)
            table.insert(stdout_lines, line)
          end
        end
      end,

      on_stderr = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then
            output.append("[stderr] " .. line)
            table.insert(stderr_lines, line)
          end
        end
      end,

      on_exit = function(_, code)
        _job_id = nil
        output.append("")
        if code == 0 then
          output.append("✓ Compilation succeeded (exit 0)")
          util.info("latex-nvim: compilation succeeded")

          -- Parse errors/warnings into quickfix even on success
          util.parse_log(tex)

          if cfg.auto_open_pdf or (on_success == "view") then
            view.open(pdf_path(tex), cfg)
          end
        else
          output.append("✗ Compilation FAILED (exit " .. code .. ")")
          util.err("latex-nvim: compilation failed (exit " .. code .. ") — see output with <localleader>lo")
          util.parse_log(tex)
          if cfg.quickfix_mode then
            vim.schedule(function() vim.cmd("copen") end)
          end
        end
      end,
    }
  )

  if _job_id <= 0 then
    util.err("latex-nvim: failed to start '" .. cfg.compile_script .. "'. Is it in $PATH?")
    _job_id = nil
  else
    util.info("latex-nvim: compiling…")
    if cfg.quickfix_mode then
      output.show(cfg)
    end
  end
end

--- Compile and then open the PDF on success.
function M.compile_and_view()
  M.compile("view")
end

--- Stop a running compilation job.
function M.stop()
  if _job_id and _job_id > 0 then
    vim.fn.jobstop(_job_id)
    _job_id = nil
    output.append("[stopped by user]")
    util.info("latex-nvim: compilation stopped")
  end
end

--- Delete auxiliary LaTeX files in the same directory as the current tex file.
function M.clean()
  local tex = get_tex_file()
  if not tex then return end
  local base = tex:gsub("%.tex$", "")
  local exts = { "aux", "log", "out", "toc", "lof", "lot", "bbl", "blg",
                 "fls", "fdb_latexmk", "synctex.gz", "nav", "snm", "vrb" }
  local removed = {}
  for _, ext in ipairs(exts) do
    local f = base .. "." .. ext
    if vim.fn.filereadable(f) == 1 then
      os.remove(f)
      table.insert(removed, vim.fn.fnamemodify(f, ":t"))
    end
  end
  if #removed == 0 then
    util.info("latex-nvim: nothing to clean")
  else
    util.info("latex-nvim: cleaned — " .. table.concat(removed, ", "))
  end
end

-- Called by init when FileType fires, to wire up per-buffer autocommands
function M.attach(cfg)
  _config = cfg
  if not cfg.compile_on_save then return end

  local group = vim.api.nvim_create_augroup("LatexNvimCompileOnSave", { clear = false })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group   = group,
    buffer  = 0,
    callback = function() M.compile() end,
  })
end

return M

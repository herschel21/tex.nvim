-- latex-nvim/keymaps.lua
-- Attaches buffer-local keymaps when a .tex file is opened

local M = {}

--- Attach all configured keymaps to the current buffer.
function M.attach(cfg)
  local km = cfg.keymaps
  if not km then return end

  local compile = require("latex-nvim.compile")
  local view    = require("latex-nvim.view")
  local output  = require("latex-nvim.output")
  local util    = require("latex-nvim.util")

  local function map(lhs, rhs, desc)
    if lhs and lhs ~= false then
      vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc, silent = true })
    end
  end

  map(km.compile,          function() compile.compile() end,          "LaTeX: compile")
  map(km.view,             function() view.open(nil, cfg) end,        "LaTeX: view PDF")
  map(km.compile_and_view, function() compile.compile_and_view() end, "LaTeX: compile & view")
  map(km.stop,             function() compile.stop() end,             "LaTeX: stop compilation")
  map(km.toggle_output,    function() output.toggle(cfg) end,         "LaTeX: toggle output window")
  map(km.clean,            function() compile.clean() end,            "LaTeX: clean aux files")
  map(km.word_count,       function() util.word_count() end,          "LaTeX: word count")
  map(km.next_error,       "<cmd>cnext<CR>",                          "LaTeX: next error/warning")
  map(km.prev_error,       "<cmd>cprev<CR>",                          "LaTeX: previous error/warning")
end

return M

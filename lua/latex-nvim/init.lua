-- latex-nvim/init.lua
-- Main module: setup, public API, and autocommands

local M = {}

-- Default configuration
M.config = {
  -- Path to your custom compile script
  compile_script = "compile_latex",

  -- PDF viewer
  viewer = "evince",

  -- Automatically compile on save
  compile_on_save = false,

  -- Open PDF after successful compile
  auto_open_pdf = false,

  -- Show compilation output in a split
  quickfix_mode = true,

  -- Compile output window height
  output_win_height = 12,

  -- Keymaps (set to false to disable a keymap)
  keymaps = {
    compile        = "<localleader>ll",
    view           = "<localleader>lv",
    compile_and_view = "<localleader>lc",
    stop           = "<localleader>ls",
    toggle_output  = "<localleader>lo",
    clean          = "<localleader>lk",
    word_count     = "<localleader>lw",
    next_error     = "<localleader>le",
    prev_error     = "<localleader>lE",
  },
}

-- Setup function — call this in your lazy spec's opts
function M.setup(user_config)
  if user_config then
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
  end

  -- Only activate for TeX files
  local group = vim.api.nvim_create_augroup("LatexNvim", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group   = group,
    pattern = { "tex", "latex", "plaintex" },
    callback = function()
      require("latex-nvim.keymaps").attach(M.config)
      require("latex-nvim.compile").attach(M.config)
    end,
  })

  -- Register user commands (available globally)
  vim.api.nvim_create_user_command("LatexCompile",     function() require("latex-nvim.compile").compile() end, {})
  vim.api.nvim_create_user_command("LatexView",        function() require("latex-nvim.view").open() end, {})
  vim.api.nvim_create_user_command("LatexCompileView", function() require("latex-nvim.compile").compile_and_view() end, {})
  vim.api.nvim_create_user_command("LatexStop",        function() require("latex-nvim.compile").stop() end, {})
  vim.api.nvim_create_user_command("LatexClean",       function() require("latex-nvim.compile").clean() end, {})
  vim.api.nvim_create_user_command("LatexWordCount",   function() require("latex-nvim.util").word_count() end, {})
  vim.api.nvim_create_user_command("LatexToggleOutput",function() require("latex-nvim.output").toggle() end, {})
end

return M

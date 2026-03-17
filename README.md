# latex-nvim

A lightweight, asynchronous LaTeX plugin for Neovim — inspired by VimTex — built around your own `compile_latex` script with live PDF preview via **evince**.

![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-blueviolet?logo=neovim)
![Lua](https://img.shields.io/badge/Made%20with-Lua-blue?logo=lua)

---

## ✨ Features

- 🔨 **Async compilation** — runs your `compile_latex` script in the background; Neovim never freezes
- 📄 **Evince integration** — opens your PDF with evince, which auto-reloads on every recompile
- 💾 **Compile on save** — edit, save, and see the PDF update automatically
- 📋 **Quickfix error navigation** — parses the `.log` file and populates the quickfix list so you can jump to errors with a keymap
- 🪟 **Optional output window** — toggle a live compilation log split on demand
- 🧹 **Clean aux files** — remove `.aux`, `.log`, `.out`, `.toc`, `.bbl` and more in one keymap
- 🔢 **Word count** — via `texcount` (falls back to a fast naive estimate)
- 📁 **Multi-file projects** — pin a root `.tex` file per buffer with `b:latex_root`

---

## 📦 Installation

### lazy.nvim

```lua
return {
  "herschel21/tex.nvim",
  ft = { "tex", "latex" },
  config = function()
    require("latex-nvim").setup({
      compile_script = "compile_latex",
      viewer         = "evince",
    })
  end,
}
```

> **Requirements**
> - Neovim 0.9+
> - `evince` installed (`sudo apt install evince`)

---

## ⚙️ Configuration

All options and their defaults:

```lua
require("latex-nvim").setup({
  compile_script    = "compile_latex",
  viewer            = "evince",
  compile_on_save   = false,
  auto_open_pdf     = false,
  quickfix_mode     = true,
  output_win_height = 12,
  keymaps = {
    compile          = "<localleader>ll",
    view             = "<localleader>lv",
    compile_and_view = "<localleader>lc",
    stop             = "<localleader>ls",
    toggle_output    = "<localleader>lo",
    clean            = "<localleader>lk",
    word_count       = "<localleader>lw",
    next_error       = "<localleader>le",
    prev_error       = "<localleader>lE",
  },
})
```

### Minimal silent setup (status bar only, no popups)

```lua
require("latex-nvim").setup({
  compile_script    = "compile_latex",
  viewer            = "evince",
  compile_on_save   = true,
  auto_open_pdf     = true,
  quickfix_mode     = false,
  output_win_height = 0,
})
```

---

## ⌨️ Keymaps

All keymaps are **buffer-local** and only active in `.tex` files.

| Keymap | Action |
|--------|--------|
| `<localleader>ll` | Compile |
| `<localleader>lv` | Open PDF in evince |
| `<localleader>lc` | Compile then open PDF |
| `<localleader>ls` | Stop running compilation |
| `<localleader>lo` | Toggle output window |
| `<localleader>lk` | Clean auxiliary files |
| `<localleader>lw` | Word count |
| `<localleader>le` | Next error / warning |
| `<localleader>lE` | Previous error / warning |

---

## 🖥️ Commands

| Command | Action |
|---------|--------|
| `:LatexCompile` | Compile |
| `:LatexView` | Open PDF |
| `:LatexCompileView` | Compile then open PDF |
| `:LatexStop` | Kill running job |
| `:LatexClean` | Remove aux files |
| `:LatexWordCount` | Word count |
| `:LatexToggleOutput` | Toggle output window |

---

## 📁 Multi-file Projects

Pin a root file so all keymaps/commands operate on it:

```vim
:let b:latex_root = "/home/you/thesis/main.tex"
```

---

## 🔧 How it works with `compile_latex`

Your script receives the **full path to the `.tex` file** as its first argument:

```bash
compile_latex /home/you/document.tex
```

A minimal example script:

```bash
#!/bin/bash
pdflatex -interaction=nonstopmode -synctex=1 "$1"
```

Make it executable: `chmod +x ~/bin/compile_latex`

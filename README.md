# latex-nvim

A lightweight, asynchronous LaTeX plugin for Neovim — inspired by VimTex.

![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-blueviolet?logo=neovim)
![Lua](https://img.shields.io/badge/Made%20with-Lua-blue?logo=lua)

---

## ✨ Features

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

The Script:

```bash
#!/bin/bash

# Function to compile the tex file
compile_latex() {
    local input_file=$1
    echo "Compiling $input_file..."
    
    # Run usr/local/texlive/2024/bin/x86_64-linux/pdflatex twice to resolve references
    pdflatex -interaction=nonstopmode "$input_file"
    if [ $? -ne 0 ]; then
        echo "Error: LaTeX compilation failed"
        return 1
    fi
    
    pdflatex -interaction=nonstopmode "$input_file"
    if [ $? -ne 0 ]; then
        echo "Error: LaTeX compilation failed"
        return 1
    fi
    
    echo "Compilation successful!"
    return 0
}

# Function to clean up auxiliary files
cleanup() {
    echo "Cleaning up auxiliary files..."
    rm -f *.aux *.log *.out *.toc *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz
    echo "Cleanup complete!"
}

# Function to display usage information
show_usage() {
    echo "Usage: $0 [options] [tex_file]"
    echo "Options:"
    echo "  --clean        Clean up auxiliary files only (no compilation)"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 document.tex         # Compile the document and clean up auxiliary files"
    echo "  $0 --clean             # Just clean up auxiliary files"
    exit 1
}

# Main script
main() {
    local clean_only=false
    local tex_file=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean_only=true
                shift
                ;;
            -h|--help)
                show_usage
                ;;
            *)
                if [[ -z "$tex_file" ]]; then
                    tex_file="$1"
                else
                    echo "Error: Multiple input files specified"
                    show_usage
                fi
                shift
                ;;
        esac
    done

    # If clean_only flag is set, just clean up and exit
    if [ "$clean_only" = true ]; then
        cleanup
        exit 0
    fi

    # Check if input file is provided for compilation
    if [[ -z "$tex_file" ]]; then
        echo "Error: No input file specified"
        show_usage
    fi

    # Check if file exists and has .tex extension
    if [[ ! -f "$tex_file" ]]; then
        echo "Error: File '$tex_file' not found"
        exit 1
    fi

    if [[ "${tex_file##*.}" != "tex" ]]; then
        echo "Error: Input file must have .tex extension"
        exit 1
    fi

    
    # Compile the document
    if compile_latex "$tex_file"; then
        # Always clean up after successful compilation
        cleanup
        echo "PDF generation complete! Output file: ${tex_file%.tex}.pdf"
    else
        echo "PDF generation failed!"
        exit 1
    fi
}

# Run the script with all command line arguments
main "$@"
```

Make it executable: `chmod +x ~/bin/compile_latex`

-- latex-nvim/util.lua
-- Notifications, LaTeX log parser, word-count, misc helpers

local M = {}

-- ── Notifications ─────────────────────────────────────────────────────────────

function M.info(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "latex-nvim" })
end

function M.warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = "latex-nvim" })
end

function M.err(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "latex-nvim" })
end

-- ── LaTeX Log Parser → quickfix ───────────────────────────────────────────────

--- Parse the .log file next to `tex_file` and populate the quickfix list.
--- Recognises:
---   • "! <error message>" blocks (with l.<lineno>)
---   • LaTeX Warning: … (line <n>)
---   • Overfull/Underfull \hbox … at lines <n>--<m>
function M.parse_log(tex_file)
  local log_file = tex_file:gsub("%.tex$", ".log")
  if vim.fn.filereadable(log_file) == 0 then return end

  local qf = {}
  local lines = {}
  for line in io.lines(log_file) do
    table.insert(lines, line)
  end

  local i = 1
  while i <= #lines do
    local line = lines[i]

    -- Hard errors: "! ..."
    if line:match("^!") then
      local msg = line:sub(3)
      local lnum = 0
      -- Look ahead for "l.<number>"
      for j = i + 1, math.min(i + 10, #lines) do
        local ln = lines[j]:match("^l%.(%d+)")
        if ln then
          lnum = tonumber(ln)
          break
        end
      end
      table.insert(qf, {
        filename = tex_file,
        lnum     = lnum,
        col      = 0,
        type     = "E",
        text     = msg,
      })

    -- LaTeX Warnings
    elseif line:match("^LaTeX Warning:") or line:match("^Package .* Warning:") then
      local msg = line
      local lnum = 0
      -- warning may continue on next lines; grab up to 3 continuation lines
      for j = i + 1, math.min(i + 3, #lines) do
        if lines[j]:match("^%s") then
          msg = msg .. " " .. lines[j]:gsub("^%s+", "")
        else
          break
        end
      end
      local ln = msg:match("[Ll]ine (%d+)")
      if ln then lnum = tonumber(ln) end
      table.insert(qf, {
        filename = tex_file,
        lnum     = lnum,
        col      = 0,
        type     = "W",
        text     = msg,
      })

    -- Overfull / Underfull hbox
    elseif line:match("^Overfull") or line:match("^Underfull") then
      local lnum = 0
      local ln = line:match("at lines (%d+)") or line:match("at line (%d+)")
      if ln then lnum = tonumber(ln) end
      table.insert(qf, {
        filename = tex_file,
        lnum     = lnum,
        col      = 0,
        type     = "W",
        text     = line,
      })
    end

    i = i + 1
  end

  vim.fn.setqflist(qf, "r")
  if #qf > 0 then
    M.info(string.format("latex-nvim: %d issue(s) found — use <localleader>le/lE to navigate", #qf))
  end
end

-- ── Word count ────────────────────────────────────────────────────────────────

--- Run `texcount` on the current file (if available) or fall back to a naive
--- word count that strips LaTeX commands.
function M.word_count()
  local tex = vim.api.nvim_buf_get_name(0)
  if tex == "" or not tex:match("%.tex$") then
    M.err("Not a .tex file")
    return
  end

  if vim.fn.executable("texcount") == 1 then
    local result = vim.fn.system("texcount -brief " .. vim.fn.shellescape(tex) .. " 2>/dev/null")
    -- texcount -brief: "Words in text: N\n..."
    local words = result:match("Words in text:%s*(%d+)")
    if words then
      M.info("Word count: " .. words .. " words (texcount)")
    else
      M.info("texcount output:\n" .. result)
    end
  else
    -- Naive fallback: strip comments and commands, count words
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local text  = table.concat(lines, " ")
    text = text:gsub("%%[^\n]*", "")          -- strip % comments
    text = text:gsub("\\%a+%b{}", " ")        -- strip \cmd{arg}
    text = text:gsub("\\%a+%b[]%b{}", " ")    -- strip \cmd[opt]{arg}
    text = text:gsub("[{}%[%]\\]", " ")        -- strip remaining braces
    local count = 0
    for _ in text:gmatch("%S+") do count = count + 1 end
    M.info("Word count: ~" .. count .. " words (naive estimate)")
  end
end

return M

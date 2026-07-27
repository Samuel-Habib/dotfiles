-- ftplugin/pdf.lua
-- Pure View-Only PDF viewer for Neovim (No editing, Headless & ANSI compatible)
-- Loaded ONLY when buffer filetype is 'pdf' (Zero overhead on non-PDF files)

local bufnr = vim.api.nvim_get_current_buf()
local filename = vim.api.nvim_buf_get_name(bufnr)

-- Strict View-Only Buffer Options
vim.bo[bufnr].modifiable = false
vim.bo[bufnr].readonly = true
vim.bo[bufnr].buftype = "nofile"
vim.bo[bufnr].swapfile = false

vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
vim.wo.cursorline = true

-- Highlight page dividers
vim.cmd [[
  syntax match PdfPageDivider /^--- Page \d\+ ---$/
  highlight default link PdfPageDivider Title
]]

-- Disable editing keys so user never accidentally enters Insert mode or gets read-only warnings
local noop = function() end
local edit_keys = { "a", "A", "o", "O", "c", "C", "s", "S", "r", "R" }
for _, key in ipairs(edit_keys) do
  vim.keymap.set("n", key, noop, { buffer = bufnr, silent = true, desc = "PDF Viewer: Editing disabled (View-Only)" })
end

-- Helper: Render page using universal ANSI symbols (works on ALL terminals, headless or SSH)
local function preview_image_ansi()
  if filename == "" or not vim.uv.fs_stat(filename) then
    vim.notify("No valid PDF file on disk for image preview", vim.log.levels.WARN)
    return
  end

  if vim.fn.executable("pdftoppm") ~= 1 or vim.fn.executable("chafa") ~= 1 then
    vim.notify("ANSI page preview requires 'pdftoppm' and 'chafa' CLI tools", vim.log.levels.WARN)
    return
  end

  local tmp_prefix = "/tmp/nvim_pdf_page_" .. vim.fn.getpid()
  local page_num = 1

  -- Find page number under cursor
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, cursor_line, false)
  for i = #lines, 1, -1 do
    local p = lines[i]:match("^--- Page (%d+) ---$")
    if p then
      page_num = tonumber(p) or 1
      break
    end
  end

  -- Use chafa --format=symbols to render standard ANSI block graphics (100% terminal compatible)
  local cmd = string.format(
    "pdftoppm -png -f %d -l %d -r 150 %s %s && chafa --format=symbols --size=80x40 %s-%d.png && rm -f %s*.png",
    page_num, page_num, vim.fn.shellescape(filename), tmp_prefix, tmp_prefix, page_num, tmp_prefix
  )

  local has_toggleterm, toggleterm = pcall(require, "toggleterm.terminal")
  if has_toggleterm and toggleterm.Terminal then
    local term = toggleterm.Terminal:new({ cmd = cmd, hidden = true, direction = "float" })
    term:toggle()
  else
    vim.cmd("split | terminal " .. cmd)
  end
end

-- Helper: Open PDF in external GUI viewer (zathura, sioyek, okular, xdg-open)
local function open_external_viewer()
  if filename == "" or not vim.uv.fs_stat(filename) then
    vim.notify("No valid PDF file on disk to open externally", vim.log.levels.WARN)
    return
  end

  local display = os.getenv("DISPLAY") or os.getenv("WAYLAND_DISPLAY")
  if not display or display == "" then
    vim.notify("No GUI desktop display ($DISPLAY) detected in this terminal. Launching Terminal ANSI Page View instead...", vim.log.levels.INFO)
    preview_image_ansi()
    return
  end

  local openers = { "zathura", "sioyek", "okular", "mupdf", "xdg-open", "open" }
  local chosen_cmd = nil

  for _, cmd in ipairs(openers) do
    if vim.fn.executable(cmd) == 1 then
      chosen_cmd = cmd
      break
    end
  end

  if not chosen_cmd then
    vim.notify("No suitable GUI PDF viewer found. Opening in Terminal ANSI Mode...", vim.log.levels.WARN)
    preview_image_ansi()
    return
  end

  vim.fn.jobstart({ chosen_cmd, filename }, { detach = true })
  vim.notify("Opening PDF in external GUI viewer: " .. chosen_cmd, vim.log.levels.INFO)
end

-- Helper: Serve PDF over HTTP for browser viewing when in headless SSH sessions
local function open_web_server()
  if filename == "" or not vim.uv.fs_stat(filename) then
    vim.notify("No valid PDF file on disk", vim.log.levels.WARN)
    return
  end

  local dir = vim.fn.fnamemodify(filename, ":h")
  local basename = vim.fn.fnamemodify(filename, ":t")
  local port = 8888

  local cmd = string.format("python3 -m http.server %d --directory %s", port, vim.fn.shellescape(dir))
  vim.fn.jobstart(cmd, { detach = true })

  local url = string.format("http://localhost:%d/%s", port, basename)
  vim.notify("Serving PDF via HTTP!\nOpen URL in your browser: " .. url, vim.log.levels.INFO, { title = "Web PDF Server" })
end

-- Helper: Jump between pages
local function jump_page(direction)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  if direction > 0 then
    for l = cursor_line + 1, total_lines do
      local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
      if line:match("^--- Page %d+ ---$") then
        vim.api.nvim_win_set_cursor(0, { l, 0 })
        return
      end
    end
  else
    for l = cursor_line - 1, 1, -1 do
      local line = vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1] or ""
      if line:match("^--- Page %d+ ---$") then
        vim.api.nvim_win_set_cursor(0, { l, 0 })
        return
      end
    end
  end
end

-- Helper: Display metadata
local function show_pdf_info()
  if filename == "" or not vim.uv.fs_stat(filename) then
    vim.notify("No valid PDF file on disk", vim.log.levels.WARN)
    return
  end

  local info = {}
  table.insert(info, "File: " .. vim.fn.fnamemodify(filename, ":t"))
  table.insert(info, "Path: " .. filename)

  local size = vim.fn.getfsize(filename)
  if size > 0 then
    table.insert(info, string.format("Size: %.2f KB", size / 1024))
  end

  if vim.fn.executable("pdfinfo") == 1 then
    local out = vim.fn.systemlist({ "pdfinfo", filename })
    if vim.v.shell_error == 0 then
      table.insert(info, "--- Metadata ---")
      for _, line in ipairs(out) do
        if line:match("^Pages:") or line:match("^Title:") or line:match("^Author:") or line:match("^Creator:") or line:match("^PDF version:") then
          table.insert(info, line)
        end
      end
    end
  end

  vim.notify(table.concat(info, "\n"), vim.log.levels.INFO, { title = "PDF Document Info" })
end

-- Keymap definitions for Pure Viewing mode
local opts = { buffer = bufnr, silent = true }

-- Navigation & External / Terminal / Web Viewers
vim.keymap.set("n", "v", open_external_viewer, vim.tbl_extend("force", opts, { desc = "PDF: Open page view" }))
vim.keymap.set("n", "o", open_external_viewer, vim.tbl_extend("force", opts, { desc = "PDF: Open page view" }))
vim.keymap.set("n", "<leader>pv", open_external_viewer, vim.tbl_extend("force", opts, { desc = "PDF: Open page view" }))

vim.keymap.set("n", "w", open_web_server, vim.tbl_extend("force", opts, { desc = "PDF: Serve over HTTP for browser" }))

-- ANSI Symbol Image Preview (Works on ALL terminals)
vim.keymap.set("n", "p", preview_image_ansi, vim.tbl_extend("force", opts, { desc = "PDF: ANSI symbol image preview" }))
vim.keymap.set("n", "<leader>pi", preview_image_ansi, vim.tbl_extend("force", opts, { desc = "PDF: ANSI symbol image preview" }))

-- Page Jumps
vim.keymap.set("n", "]p", function() jump_page(1) end, vim.tbl_extend("force", opts, { desc = "PDF: Next page" }))
vim.keymap.set("n", "[p", function() jump_page(-1) end, vim.tbl_extend("force", opts, { desc = "PDF: Previous page" }))

-- Metadata & Close
vim.keymap.set("n", "g?", show_pdf_info, vim.tbl_extend("force", opts, { desc = "PDF: Document Info" }))
vim.keymap.set("n", "<leader>pg", show_pdf_info, vim.tbl_extend("force", opts, { desc = "PDF: Document Info" }))
vim.keymap.set("n", "q", function() vim.api.nvim_buf_delete(bufnr, { force = true }) end, vim.tbl_extend("force", opts, { desc = "PDF: Close viewer buffer" }))

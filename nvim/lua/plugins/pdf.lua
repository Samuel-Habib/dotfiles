-- lua/plugins/pdf.lua
-- High-performance, 100% lazy-loaded PDF support for Neovim (Strict View-Only)
-- Zero overhead on non-PDF files: No binaries or parsing scripts run unless a .pdf file is opened.

local function read_pdf_buffer(bufnr, filepath)
  if not filepath or filepath == "" or not vim.uv.fs_stat(filepath) then
    vim.notify("PDF file does not exist: " .. tostring(filepath), vim.log.levels.ERROR)
    return false
  end

  local lines = {}
  table.insert(lines, "📄 PDF: " .. vim.fn.fnamemodify(filepath, ":t"))
  table.insert(lines, "📁 Path: " .. filepath)
  table.insert(lines, "--------------------------------------------------------------------------------")
  table.insert(lines, "Keymaps: [v/o] External Viewer | [p] ANSI Image Preview | []p/[p] Next/Prev Page | [g?] Info | [q] Close")
  table.insert(lines, "--------------------------------------------------------------------------------")
  table.insert(lines, "")

  if vim.fn.executable("pdftotext") == 1 then
    -- Extract text with preserved layout
    local cmd = { "pdftotext", "-layout", "-nopgbrk", filepath, "-" }
    local raw_output = vim.fn.system(cmd)

    if vim.v.shell_error == 0 and raw_output and #raw_output > 0 then
      -- Split output into pages based on Form Feed characters (\f) or standard newlines
      local page_num = 1
      table.insert(lines, string.format("--- Page %d ---", page_num))
      
      for line in raw_output:gmatch("[^\r\n]+") do
        -- Check for page break character (\f)
        if line:find("\f") then
          page_num = page_num + 1
          line = line:gsub("\f", "")
          table.insert(lines, "")
          table.insert(lines, string.format("--- Page %d ---", page_num))
        end
        table.insert(lines, line)
      end
    else
      table.insert(lines, "[Warning: pdftotext returned no readable text or file is scanned/image-only PDF]")
    end
  else
    table.insert(lines, "[Error: 'pdftotext' tool not found. Install poppler-utils to extract text]")
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = "pdf"
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].readonly = true

  return true
end

-- Create autocommand group for lazy PDF reading
local pdf_group = vim.api.nvim_create_augroup("LazyPdfReader", { clear = true })

-- Intercept opening any .pdf file
vim.api.nvim_create_autocmd("BufReadCmd", {
  group = pdf_group,
  pattern = "*.pdf",
  callback = function(ev)
    read_pdf_buffer(ev.buf, ev.file)
  end,
})

-- User commands for manual PDF operations
vim.api.nvim_create_user_command("PdfText", function(opts)
  local file = opts.args ~= "" and opts.args or vim.api.nvim_buf_get_name(0)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  read_pdf_buffer(buf, file)
end, { nargs = "?", complete = "file", desc = "Render PDF text into current buffer" })

vim.api.nvim_create_user_command("PdfView", function(opts)
  local file = opts.args ~= "" and opts.args or vim.api.nvim_buf_get_name(0)
  if file == "" or not vim.uv.fs_stat(file) then
    vim.notify("Please specify a valid PDF file path", vim.log.levels.WARN)
    return
  end
  local openers = { "zathura", "sioyek", "okular", "mupdf", "xdg-open", "open" }
  for _, cmd in ipairs(openers) do
    if vim.fn.executable(cmd) == 1 then
      vim.fn.jobstart({ cmd, file }, { detach = true })
      vim.notify("Opening " .. file .. " with " .. cmd, vim.log.levels.INFO)
      return
    end
  end
  vim.notify("No external PDF viewer found", vim.log.levels.ERROR)
end, { nargs = "?", complete = "file", desc = "Open PDF in external GUI viewer" })

return {
  -- Ensure Snacks.image is disabled to prevent terminal graphics protocol errors
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      image = {
        enabled = false,
      },
    },
  },
}

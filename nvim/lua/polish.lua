local aug = vim.api.nvim_create_augroup
local ac  = vim.api.nvim_create_autocmd

-- Soft-wrap & sane prose defaults (if you don't already have this block)
ac("FileType", {
  group = aug("md_wrap", { clear = true }),
  pattern = { "markdown", "markdown.mdx" },
  callback = function()
    vim.wo.wrap        = true
    vim.wo.linebreak   = true
    vim.wo.breakindent = true
    vim.wo.showbreak   = "↳ "
    vim.bo.textwidth   = 0
    vim.bo.formatoptions = "qnjro"
  end,
})

-- Conceal long URLs in links/images/autolinks
ac("FileType", {
  group = aug("md_conceal_urls", { clear = true }),
  pattern = "markdown",
  callback = function()
    local o = vim.opt_local
    o.conceallevel  = 2
    o.concealcursor = "nc"
    vim.cmd([=[
      syntax match mdConcealLink  /\v\]\zs\([^)]*\)/ conceal
      syntax match mdConcealImage /\v!\[[^]]*\]\zs\([^)]*\)/ conceal
      syntax match mdConcealAuto  /\v<https?:\/\/[^>]+>/ conceal cchar=↗
      highlight link mdConcealLink  Conceal
      highlight link mdConcealImage Conceal
      highlight link mdConcealAuto  Conceal
    ]=])
  end,
})

-- Bold token before '::' and conceal EXACTLY '::' as ':'
do
  local grp = aug("md_double_colon_rules", { clear = true })
  local function apply()
    vim.opt_local.conceallevel  = 2
    vim.opt_local.concealcursor = "nc"
    vim.api.nvim_set_hl(0, "MdColonBoldHL", { bold = true })
    if vim.w.md_bold_id then pcall(vim.fn.matchdelete, vim.w.md_bold_id) end
    if vim.w.md_conc_id then pcall(vim.fn.matchdelete, vim.w.md_conc_id) end
    vim.w.md_bold_id = vim.fn.matchadd("MdColonBoldHL", [[\v\S+\ze::]], 200)
    vim.w.md_conc_id = vim.fn.matchadd("Conceal", [[\v(^|[^:])\zs::\ze([^:]|$)]], 200, -1, { conceal = ":" })
  end
  ac({ "FileType", "BufWinEnter" }, { group = grp, pattern = "markdown", callback = apply })
  ac({ "TextChanged", "TextChangedI", "ColorScheme", "OptionSet" }, {
    group = grp, pattern = "markdown", callback = apply,
  })
end

-- Table-aware Alt-Enter: create next row
do
  local function md_table_newline()
    local line = vim.api.nvim_get_current_line()
    if line:match("^%s*|") then
      local cols = 0; for _ in line:gmatch("|") do cols = cols + 1 end
      cols = math.max(cols - 1, 1)
      local newrow = ("| "):rep(cols) .. "|"
      return "<Esc>o" .. newrow .. "<Esc>0f|la"
    end
    return "<CR>"
  end
  ac("FileType", {
    group = aug("md_table_enter", { clear = true }),
    pattern = "markdown",
    callback = function(args)
      vim.keymap.set("i", "<A-CR>", md_table_newline, { buffer = args.buf, expr = true, desc = "MD table: new row" })
      vim.keymap.set("n", "<A-CR>", function()
        local line = vim.api.nvim_get_current_line()
        if line:match("^%s*|") then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(md_table_newline(), true, false, true), "i", false)
        else
          vim.api.nvim_feedkeys("o", "n", false)
        end
      end, { buffer = args.buf, desc = "MD table: new row" })
    end,
  })
end

-- ZK: follow [[wikilink]] with `gd` or <CR> (fallback to newline)
do
  local function zk_follow_under_cursor()
    local line = vim.api.nvim_get_current_line()
    local col  = vim.api.nvim_win_get_cursor(0)[2] + 1
    local s,e; local i = 1
    while true do
      local ss, ee = line:find("%[%[[^%]]-%]%]", i)
      if not ss then break end
      if col >= ss and col <= ee then s, e = ss, ee; break end
      i = ee + 1
    end
    if not s then return false end
    local inner  = line:sub(s, e):match("%[%[([^%]]-)%]%]")
    local target = inner:gsub("%s*|.*$", "")
    local ok, zkc = pcall(require, "zk.commands")
    if not ok then return false end
    local open = zkc.get("ZkNotes"); if not open then return false end
    open({
      match = { target },
      sort = { "created" },
      editable = true,
      notebook_path = vim.fn.expand("~/Obsidian/second-brain"),
    })
    return true
  end
  ac("FileType", {
    group = aug("md_zk_links", { clear = true }),
    pattern = "markdown",
    callback = function(args)
      vim.keymap.set("n", "gd", function()
        if not zk_follow_under_cursor() then vim.notify("No [[link]] under cursor", vim.log.levels.WARN) end
      end, { buffer = args.buf, desc = "ZK: follow [[link]]" })
      vim.keymap.set("n", "<CR>", function()
        if not zk_follow_under_cursor() then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("\n", true, false, true), "n", false)
        end
      end, { buffer = args.buf, desc = "ZK: follow [[link]] or newline" })
    end,
  })
end



-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

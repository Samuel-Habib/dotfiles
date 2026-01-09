
-- Override / add your personal keymaps in AstroNvim
return {
  "AstroNvim/astrocore",
  opts = function(_, opts)
    ---------------------------------------------------------------------------
    -- helpers (your second-brain functions)
    ---------------------------------------------------------------------------
    local function open_daily_note()
      local ROOT      = vim.fn.expand("~/Obsidian/second-brain")
      local daily_dir = ROOT .. "/10_daily/"
      vim.fn.mkdir(daily_dir, "p")

      local date     = os.date("%m.%d.%y")
      local filename = daily_dir .. "_" .. date .. ".md"
      local template = ROOT .. "/templates/daily.md"

      if vim.fn.filereadable(filename) == 0 then
        local content
        if vim.fn.filereadable(template) == 1 then
          content = table.concat(vim.fn.readfile(template), "\n")
          content = content:gsub("{{date}}", date) 
        else
          content = ([[# {{date}}

## Tasks
- [ ]

## Notes
-

## Reflections
- ]]):gsub("{{date}}", date)
        end
        vim.fn.writefile(vim.split(content, "\n"), filename)
      end
      vim.cmd("edit " .. filename)
    end

    local function insert_template(name)
      local ROOT = vim.fn.expand("~/Obsidian/second-brain")
      local path = ROOT .. "/templates/" .. name .. ".md"
      if vim.fn.filereadable(path) == 0 then
        print("Template not found: " .. path)
        return
      end
      local content = table.concat(vim.fn.readfile(path), "\n")
      content = content:gsub("{{date}}", os.date("%m.%d.%y"))
      vim.api.nvim_put(vim.split(content, "\n"), "l", true, true)
    end

    local function xcodebuild_setup()
      vim.cmd("XcodebuildSelectProject")
      vim.cmd("XcodebuildSelectScheme")
      vim.cmd("XcodebuildSelectDevice")
    end

    ---------------------------------------------------------------------------
    -- mappings
    ---------------------------------------------------------------------------
    opts.mappings = opts.mappings or {}
    local n = vim.tbl_deep_extend("force", opts.mappings.n or {}, {
      -- basics
      ["<Esc>"] = { "<cmd>nohlsearch<CR>", desc = "Clear search highlights" },

      -- window nav
      ["<C-h>"] = { "<C-w><C-h>", desc = "Focus left" },
      ["<C-j>"] = { "<C-w><C-j>", desc = "Focus down" },
      ["<C-k>"] = { "<C-w><C-k>", desc = "Focus up" },
      ["<C-l>"] = { "<C-w><C-l>", desc = "Focus right" },

      -- diagnostics quickfix (from your old init)
      ["<leader>q"] = { vim.diagnostic.setloclist, desc = "Diagnostics list" },

      -- Xcodebuild / Swift workflow
      ["<leader>xb"] = { "<cmd>XcodebuildBuild<cr>", desc = "Build (Xcodebuild)" },
      ["<leader>xr"] = { "<cmd>XcodebuildRun<cr>", desc = "Run on simulator" },
      ["<leader>xt"] = { "<cmd>XcodebuildTest<cr>", desc = "Test (Xcodebuild)" },
      ["<leader>xk"] = { "<cmd>XcodebuildCleanBuild<cr>", desc = "Clean build folder" },
      ["<leader>xs"] = { "<cmd>XcodebuildSelectScheme<cr>", desc = "Select scheme" },
      ["<leader>xd"] = { "<cmd>XcodebuildSelectDevice<cr>", desc = "Select device" },
      ["<leader>xl"] = { "<cmd>XcodebuildToggleLogs<cr>", desc = "Toggle App Logs" },

      -- SECOND BRAIN
      ["<leader>da"]  = { open_daily_note,                     desc = "Open Daily Note" },
      ["<leader>tp"] = { function() insert_template("project") end, desc = "Insert Project Template" },
      ["<leader>ta"] = { function() insert_template("area")    end, desc = "Insert Area Template" },

      -- STM32 helpers
      ["<leader>mb"] = { function() vim.cmd("w") vim.cmd("terminal make -j") end, desc = "Make build" },
      ["<leader>mf"] = { function() vim.cmd("w") vim.cmd("terminal make flash") end, desc = "Make flash" },
      ["<leader>mo"] = { function() vim.cmd("terminal openocd -f openocd.cfg") end, desc = "OpenOCD" },

      -- HAL/CMSIS docs (adjust FW path if needed)
      ["<leader>hd"] = { function()
        local fw = vim.env.HOME .. "/STM32Cube/Repository/STM32Cube_FW_F4_V1.28.3"
        vim.fn.jobstart({ "open", fw.."/Drivers/STM32F4xx_HAL_Driver/Documentation/index.html" })
      end, desc = "Open HAL Docs" },
      ["<leader>hc"] = { function()
        local fw = vim.env.HOME .. "/STM32Cube/Repository/STM32Cube_FW_F4_V1.28.3"
        vim.fn.jobstart({ "open", fw.."/Drivers/CMSIS/Documentation/Core/html/index.html" })
      end, desc = "Open CMSIS Docs" },
    })

    local t = vim.tbl_deep_extend("force", opts.mappings.t or {}, {
      ["<Esc><Esc>"] = { "<C-\\><C-n>", desc = "Exit terminal mode" },
    })

    -- OPTIONAL: if any Astro defaults collide and you want them gone:
    -- n["<leader>ff"] = false  -- example: remove a default mapping

    opts.mappings.n = n
    opts.mappings.t = t
    return opts
  end,
}

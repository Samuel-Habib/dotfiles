
-- lua/plugins/markdown.lua
return {
  -- Inline MD rendering (headings, tables, checkboxes, callouts)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      enabled = true,
      file_types = { "markdown" },
      treesitter = { ensure_installed = false },
    },
  },

  -- Better list bullets / checkbox ergonomics
  { "dkarter/bullets.vim", ft = { "markdown" } },

  -- Paste images from clipboard to file + markdown link
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      default = {
        dir_path = "90_assets",
        file_name = "%Y-%m-%d-%H%M%S",
        use_absolute_path = false,
        template = "![$LABEL]($FILE_PATH)",
      },
    },
  },

  -- Display images inline (Kitty/WezTerm backends)
  {
    "3rd/image.nvim",
    ft = { "markdown" },
    opts = {
      backend = "kitty",
      integrations = { markdown = { enabled = true } },
      max_width = 60,
      max_height = 20,
    },
  },

  -- Telescope-backed Zettelkasten integration
  {
    "mickael-menu/zk-nvim",
    ft = { "markdown" },
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("zk").setup({
        picker = "telescope",
        auto_attach = { enabled = true },
      })
    end,
  },

  -- Optional: markdown preview in browser
  {
    "iamcco/markdown-preview.nvim",
    ft = { "markdown" },
    build = "cd app && npm ci",
    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },

  -- Optional: table helpers (toggle with <leader>tm)
  {
    "dhruvasagar/vim-table-mode",
    ft = { "markdown" },
    config = function()
      vim.keymap.set("n", "<leader>tm", ":TableModeToggle<CR>", { desc = "Toggle Table Mode" })
      vim.g.table_mode_always_active = 0
    end,
  },
}

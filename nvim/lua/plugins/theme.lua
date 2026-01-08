---@type LazySpec
return {
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,
    config = function()
      require("nightfox").setup {
        options = {
          transparent = false,
          dim_inactive = false,
          terminal_colors = true,
        },
        palettes = {
          dawnfox = {
            bg1 = "#f7f2e7", -- soft beige editor background
            bg0 = "#efe9dd",
          },
        },
      }
      vim.cmd.colorscheme "dawnfox" -- or "dayfox" for pure light
    end,
  },
}

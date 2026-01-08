return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master", -- This branch fixes the --no-bindings error
  build = ":TSUpdate",
  opts = {
    ensure_installed = { "lua", "vim", "swift" },
  },
}

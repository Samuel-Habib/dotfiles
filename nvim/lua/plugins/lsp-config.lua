---@type LazySpec
return {
  "neovim/nvim-lspconfig",
  opts = {
    setup = {
      sourcekit = function(_, opts)
        local lspconfig = require "lspconfig"
        lspconfig.sourcekit.setup {
          capabilities = {
            workspace = {
              didChangeWatchedFiles = {
                dynamicRegistration = true,
              },
            },
          },
          on_attach = function(client, bufnr)
            if vim.lsp.inlay_hint then vim.lsp.inlay_hint.enable(false, { bufnr = bufnr }) end
          end,
        } -- Fully closed parenthesis fixes the E518 modeline crash
        return true
      end,
    },
  },
}

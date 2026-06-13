---@type LazySpec
--- lua/plugins/astrolsp.lua
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      codelens = true,
      inlay_hints = true,
      semantic_tokens = true,
    },
    formatting = {
      format_on_save = {
        enabled = true,
      },
      timeout_ms = 2000,
    },
    servers = {
      "sourcekit",
      "clangd",
    },
    config = {
      sourcekit = {
        cmd = { "xcrun", "sourcekit-lsp" },
        root_dir = function(fname)
          local util = require "lspconfig.util"
          return util.root_pattern("Package.swift", "*.xcodeproj", "*.xcworkspace")(fname)
            or util.find_git_ancestor(fname)
        end,
      },
      clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--compile-commands-dir=build",
          (function()
            if vim.fn.executable "arm-none-eabi-gcc" == 1 then
              return "--query-driver=" .. vim.fn.exepath "arm-none-eabi-gcc"
            else
              -- Standard fallback location if not found in the global path environment
              return "--query-driver=/opt/homebrew/bin/arm-none-eabi-gcc"
            end
          end)(),
        },
        capabilities = {
          offsetEncoding = "utf-8",
        },
        root_dir = function(fname)
          return require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname)
        end,
      },
    },
  },
}

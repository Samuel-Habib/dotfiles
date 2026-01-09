
-- AstroLSP allows you to customize the features in AstroNvim's LSP configuration engine
-- Configuration documentation can be found with `:h astrolsp`
-- NOTE: We highly recommend setting up the Lua Language Server (`:LspInstall lua_ls`)
--       as this provides autocomplete and documentation while editing

---@type LazySpec
--- lua/plugins/astrolsp.lua
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      codelens = true,
      inlay_hints = true, -- Helpful for Swift types
      semantic_tokens = true,
    },
    formatting = {
      format_on_save = {
        enabled = true,
      },
      timeout_ms = 2000, -- Swift formatting can be slow
    },
    servers = {
      "sourcekit", -- The official Apple LSP
    },
    -- Customize how sourcekit works if needed
    config = {
      sourcekit = {
        cmd = { "xcrun", "sourcekit-lsp" }, -- Use the Xcode toolchain version
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return util.root_pattern("Package.swift", "*.xcodeproj", "*.xcworkspace")(fname)
            or util.find_git_ancestor(fname)
        end,
      },
    },
  },
}

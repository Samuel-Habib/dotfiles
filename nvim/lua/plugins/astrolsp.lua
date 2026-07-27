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
    mappings = {
      n = {
        ["gd"] = {
          function()
            vim.lsp.buf.definition {
              on_list = function(options)
                local items = options.items
                if not items or #items == 0 then return end

                local unique_items = {}
                local seen_paths = {}

                for _, item in ipairs(items) do
                  local path = item.filename
                  if path and not seen_paths[path] then
                    seen_paths[path] = true
                    table.insert(unique_items, item)
                  end
                end

                vim.fn.setqflist({}, " ", { title = options.title, items = unique_items })

                if #unique_items == 1 then
                  vim.cmd "cfirst"
                else
                  vim.cmd "copen"
                end
              end,
            }
          end,
          desc = "LSP: Go to definition (Deduplicated)",
        },
      },
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
          "-j=2",
          "--malloc-trim",
          "--pch-storage=disk",
          "--background-index",
          "--background-index-priority=low",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--query-driver=/usr/bin/arm-none-eabi-gcc,/usr/bin/gcc*,/usr/bin/clang*,/root/.platformio/packages/toolchain-xtensa-esp32/bin/*,/root/.platformio/packages/toolchain-xtensa-esp-elf/bin/*",
          "--limit-results=100",
        },
        capabilities = {
          positionEncodings = { "utf-16", "utf-8" },
        },
        root_dir = function(fname)
          return require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname)
        end,
      },
    },
  },
}

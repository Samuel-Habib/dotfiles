---@type LazySpec
return {
  "mfussenegger/nvim-dap",
  event = "User AstroFile",
  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      dependencies = { "nvim-neotest/nvim-nio" },
      opts = {},
      config = function(_, opts)
        local dap, dapui = require "dap", require "dapui"
        dapui.setup(opts)
        dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
        dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
        dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      end,
    },
  },
  config = function()
    local dap = require "dap"

    -- 1. Register the unified GDB executable adapter
    dap.adapters.gdb = {
      type = "executable",
      command = "arm-none-eabi-gdb", -- Cross-compilation GDB binary path
      name = "gdb",
    }

    -- 2. Configure target-specific execution profiles for C
    dap.configurations.c = {
      {
        name = "Attach to OpenOCD Server",
        type = "gdb",
        request = "attach",
        target = "localhost:3333", -- Loops into standard local OpenOCD daemon listening port
        cwd = "${workspaceFolder}",
        program = function()
          -- Searches dynamically for your compiled ELF binary in the local build tree
          return vim.fn.input("Path to target ELF binary: ", vim.fn.getcwd() .. "/build/", "file")
        end,
        stopOnEntry = true,
        setupCommands = {
          {
            text = "-enable-pretty-printing",
            description = "Enable GDB variable structural formatting",
            ignoreFailures = false,
          },
        },
        initCommands = function()
          -- Direct structural commands passed sequentially to target MCU hardware
          return {
            "target remote localhost:3333",
            "monitor reset halt",
            "load",
          }
        end,
      },
    }
  end,
}

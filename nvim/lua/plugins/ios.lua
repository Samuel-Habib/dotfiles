return {
  {
    "wojciech-kulik/xcodebuild.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "MunifTanjim/nui.nvim" },
    config = function()
      require("xcodebuild").setup({
        show_build_progress_bar = true,
        logs = {
          auto_open_on_success_build = false,
          auto_open_on_failed_build = true,
          auto_open_on_success_tests = false,
          auto_open_on_failed_tests = true,
          auto_focus = false,
        },
        -- This is the key setting for your print statements
        live_logs = true, 
      })
    end,
  },
}

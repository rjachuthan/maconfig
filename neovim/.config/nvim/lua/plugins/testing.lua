-- Additional testing configuration
-- Note: test.core extras must be enabled in lazy.lua
return {
  -- neotest: Testing framework
  {
    "nvim-neotest/neotest",
    keys = {
      -- Override or add custom test keybindings here if needed
      {
        "<leader>tF",
        function()
          require("neotest").run.run(vim.fn.expand("%:p:h"))
        end,
        desc = "Run all tests in folder",
      },
    },
    opts = {
      -- Global neotest options
      output = {
        open_on_run = true,
      },
      quickfix = {
        open = false,
      },
      status = {
        enabled = true,
        signs = true,
        virtual_text = true,
      },
      icons = {
        running_animated = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      },
    },
  },
}

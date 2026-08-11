local icons = require("core.icons")

return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        desc = "Conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down stack frame" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up stack frame" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
      {
        "<leader>da",
        function() require("dap").run_last({ args = vim.split(vim.fn.input("Args: "), " ") }) end,
        desc = "Run with args",
      },

      { "<F5>", function() require("dap").continue() end, desc = "Debug: Continue" },
      { "<S-F5>", function() require("dap").terminate() end, desc = "Debug: Terminate" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step into" },
      { "<S-F11>", function() require("dap").step_out() end, desc = "Debug: Step out" },
    },
    config = function()
      local dap = require("dap")

      for name, icon in pairs(icons.dap) do
        if type(icon) == "table" then
          local text, texthl, linehl = icon[1], icon[2], icon[3]
          vim.fn.sign_define("Dap" .. name, { text = text, texthl = texthl, linehl = linehl })
        else
          vim.fn.sign_define("Dap" .. name, { text = icon, texthl = "DiagnosticInfo" })
        end
      end

      vim.api.nvim_set_hl(0, "DapStoppedLine", { link = "Visual" })

      require("mason-nvim-dap").setup({
        automatic_installation = true,
        handlers = {
          python = function() end,
        },
      })
    end,
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    keys = {
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },

  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    event = "VeryLazy",
    opts = {},
  },

  {
    "jay-babu/mason-nvim-dap.nvim",
    lazy = true,
    dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap" },
  },
}

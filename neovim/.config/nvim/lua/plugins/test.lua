return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    keys = {
      { "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file" },
      {
        "<leader>tT",
        function()
          for _, adapter_id in ipairs(require("neotest").state.adapter_ids()) do
            require("neotest").run.run({ suite = true, adapter = adapter_id })
          end
        end,
        desc = "Run all test files",
      },
      { "<leader>tr", function() require("neotest").run.run() end, desc = "Run nearest" },
      { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run last" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle summary" },
      { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Show output" },
      { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle output panel" },
      { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop" },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle watch" },
      { "<leader>ta", function() require("neotest").run.attach() end, desc = "Attach" },
      {
        "<leader>td",
        function() require("neotest").run.run({ strategy = "dap" }) end,
        desc = "Debug nearest (requires dap)",
      },
      {
        "<leader>tF",
        function() require("neotest").run.run(vim.fn.expand("%:p:h")) end,
        desc = "Run all tests in folder",
      },
    },
    opts = {
      adapters = {},
      status = { virtual_text = true },
      output = { open_on_run = true },
    },
    config = function(_, opts)
      local resolved = {}
      for _, adapter in ipairs(opts.adapters) do
        if type(adapter) == "table" and not adapter.name and next(adapter) ~= nil then
          local key, value = next(adapter)
          if type(key) == "string" and adapter[1] == nil then
            table.insert(resolved, require(key)(value or {}))
          else
            table.insert(resolved, adapter)
          end
        else
          table.insert(resolved, adapter)
        end
      end
      opts.adapters = resolved

      if pcall(require, "trouble") then
        opts.consumers = opts.consumers or {}
        opts.consumers.trouble = function(client)
          client.listeners.results = function(adapter_id, results, partial)
            if partial then
              return
            end
            local failed = {}
            for _, pos_id in pairs(vim.tbl_keys(results)) do
              local result = results[pos_id]
              if result.status == "failed" then
                table.insert(failed, pos_id)
              end
            end
            if #failed > 0 then
              vim.cmd("Trouble quickfix")
            end
          end
        end
      end

      require("neotest").setup(opts)
    end,
  },
}

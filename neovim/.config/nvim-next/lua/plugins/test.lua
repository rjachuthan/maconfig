--- ===========================================================================
--- TEST (neotest)
--- ===========================================================================
--- LEADER COLLISION FIXED HERE: in the old config, <leader>t was claimed by
--- BOTH toggleterm (13 maps) and neotest (10 maps) -- a real, daily-annoyance
--- collision where the which-key popup showed two unrelated groups fighting
--- over one prefix. Test wins <leader>t; terminal moved to <leader>T (see
--- plugins/tools.lua). Do not put anything else under <leader>t, and do not
--- move toggleterm back.
---
--- This file owns neotest's core setup and keymaps only. Language-specific
--- test ADAPTERS (neotest-python, neotest-vitest, ...) are contributed by
--- lang-file agents -- see the CONTRACT comment below for exactly how.
--- ===========================================================================

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
      --- Custom, carried over from the old config: run every test in the
      --- directory of the current file, not just the current file itself.
      {
        "<leader>tF",
        function() require("neotest").run.run(vim.fn.expand("%:p:h")) end,
        desc = "Run all tests in folder",
      },
    },
    --- -----------------------------------------------------------------------
    --- ADAPTER CONTRACT -- read this before adding a neotest-* adapter
    --- -----------------------------------------------------------------------
    --- `opts.adapters` starts empty here. Lang-file agents (lua/plugins/lang/
    --- python.lua for neotest-python, lua/plugins/lang/*.lua for
    --- neotest-vitest, etc.) extend it via lazy.nvim's `opts` function-merge
    --- form, e.g.:
    ---
    ---   { "nvim-neotest/neotest", opts = function(_, opts)
    ---       table.insert(opts.adapters, { ["neotest-python"] = { dap = { justMyCode = false } } })
    ---       return opts
    ---     end }
    ---
    --- Each entry in the list may be EITHER shape:
    ---   1. An already-constructed adapter object -- the result of calling
    ---      `require("neotest-python")({ ... })` yourself. Used as-is.
    ---   2. A `{ [require_path] = config }` pair -- a single-key table whose
    ---      key is the module to `require`, and whose value is passed to it
    ---      as the constructor config (or `{}`/`nil` for defaults). This form
    ---      defers the `require()` (and thus the plugin needing to already be
    ---      on the runtimepath) until THIS file's `config` function runs
    ---      below, which is friendlier to lazy-loading than constructing the
    ---      adapter at spec-definition time in the lang file.
    --- The resolution shim in `config` below normalises both shapes before
    --- calling `neotest.setup()`. If neither shape matches (e.g. the value
    --- isn't a table, or a multi-key table), the entry is passed through
    --- unchanged and neotest will likely error loudly -- that's intentional,
    --- it means a lang file didn't follow the contract.
    opts = {
      adapters = {},
      status = { virtual_text = true },
      output = { open_on_run = true },
    },
    config = function(_, opts)
      local resolved = {}
      for _, adapter in ipairs(opts.adapters) do
        if type(adapter) == "table" and not adapter.name and next(adapter) ~= nil then
          --- Distinguish shape (2) `{ [require_path] = config }` from an
          --- already-constructed adapter object: constructed adapters are
          --- callable/have a `name` field, config pairs are plain tables
          --- keyed by a single string require-path with no numeric index 1.
          local key, value = next(adapter)
          if type(key) == "string" and adapter[1] == nil then
            table.insert(resolved, require(key)(value or {}))
          else
            table.insert(resolved, adapter)
          end
        else
          --- Shape (1): already a constructed adapter (or a bare require
          --- result used directly) -- pass through untouched.
          table.insert(resolved, adapter)
        end
      end
      opts.adapters = resolved

      --- Route the quickfix consumer to Trouble when it's loaded, so failed
      --- tests show up in the same panel as diagnostics/LSP results instead
      --- of the plain quickfix window. Guarded with pcall: trouble.nvim is
      --- itself lazy-loaded (see lsp.lua), so it may not be `require`-able
      --- yet the first time this runs.
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

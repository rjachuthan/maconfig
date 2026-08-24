return {
  {
    "tpope/vim-dadbod",
    cmd = { "DB" },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Toggle DBUI" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_execute_on_save = false
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui_queries"
      vim.g.db_ui_use_nvim_notify = true

      vim.g.omni_sql_default_compl_type = "syntax"
      vim.g.loaded_sql_completion = true

      -- Upstream's Snowflake adapter has no tables() hook and dadbod-ui has no
      -- Snowflake schema of its own, so the drawer would list nothing.
      vim.g.db_adapter_snowflake = "db#adapter#snowflake_kp#"

      -- The default helper is `SELECT * from "{table}" LIMIT 200;`, which
      -- quotes SCHEMA.TABLE as a single identifier and fails to resolve.
      vim.g.db_ui_table_helpers = vim.tbl_deep_extend("force", vim.g.db_ui_table_helpers or {}, {
        snowflake = { List = "SELECT * FROM {table} LIMIT 200;" },
      })

      vim.g.dbs = require("util.db").connections()
    end,
  },

  {
    "kristijanhusak/vim-dadbod-completion",
    ft = { "sql", "mysql", "plsql" },
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      if not vim.tbl_contains(opts.sources.default, "dadbod") then
        table.insert(opts.sources.default, "dadbod")
      end
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.dadbod = {
        name = "Dadbod",
        module = "vim_dadbod_completion.blink",
      }
      return opts
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        sql = { "sqlfluff" },
      },
      formatters = {
        sqlfluff = {
          args = { "format", "--dialect=ansi", "-" },
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sql = { "sqlfluff" },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "sqlfluff" })
      return opts
    end,
  },

  {
    "hat0uma/csvview.nvim",
    ft = { "csv", "tsv" },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle", "CsvViewInfo" },
    keys = {
      { "<leader>Ct", "<cmd>CsvViewToggle<cr>", desc = "Toggle view", ft = { "csv", "tsv" } },
      { "<leader>Ci", "<cmd>CsvViewInfo<cr>", desc = "Show info", ft = { "csv", "tsv" } },
      { "<leader>Ce", "<cmd>CsvViewEnable<cr>", desc = "Enable view", ft = { "csv", "tsv" } },
      { "<leader>Cd", "<cmd>CsvViewDisable<cr>", desc = "Disable view", ft = { "csv", "tsv" } },
    },
    opts = {
      parser = {
        delimiter = {
          default = ",",
          ft = { tsv = "\t" },
        },
        comments = { "#", "//" },
        quote_char = '"',
        async = { enable = true, chunksize = 50 },
        max_lookahead = 50,
      },
      view = {
        min_column_width = 5,
        spacing = 2,
        display_mode = "border",
        header = { auto = true, lnum = 1 },
        sticky_header = { enabled = true, separator = "\u{2500}" },
      },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" }, desc = "CSV: Inner field" },
        textobject_field_outer = { "af", mode = { "o", "x" }, desc = "CSV: Outer field" },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" }, desc = "CSV: Next field" },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" }, desc = "CSV: Previous field" },
        jump_next_row = { "<CR>", mode = { "n", "v" }, desc = "CSV: Next row" },
        jump_prev_row = { "<S-CR>", mode = { "n", "v" }, desc = "CSV: Previous row" },
      },
    },
    config = function(_, opts)
      require("csvview").setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv" },
        group = vim.api.nvim_create_augroup("nvim_lang_csv_autoview", { clear = true }),
        callback = function(event)
          -- snacks.bigfile marks buffers it has stripped down. Parsing and
          -- aligning every column of a multi-GB extract locks the editor,
          -- and it's exactly the file you're most likely to open by
          -- accident. `:CsvViewEnable` still works if you really want it.
          if vim.b[event.buf].bigfile then
            return
          end
          vim.cmd("CsvViewEnable")
        end,
        desc = "Auto-enable CSV view for CSV/TSV files that aren't huge",
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "CsvViewAttach",
        callback = function()
          vim.wo.wrap = false
          vim.wo.cursorcolumn = true
        end,
        desc = "CSV view attached",
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "CsvViewDetach",
        callback = function()
          vim.wo.cursorcolumn = false
        end,
        desc = "CSV view detached",
      })
    end,
  },
}

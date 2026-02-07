return {
  -- vim-dadbod: Database interface
  {
    "tpope/vim-dadbod",
    dependencies = {
      "kristijanhusak/vim-dadbod-completion",
      "kristijanhusak/vim-dadbod-ui",
    },
  },

  -- vim-dadbod-ui: Database explorer
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Toggle DBUI" },
    },
    init = function()
      -- DBUI settings
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_winwidth = 40

      -- Save queries in data directory
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui_queries"

      -- Auto-execute table helpers (show columns/indexes when selecting table)
      vim.g.db_ui_auto_execute_table_helpers = 1

      -- Disable auto-execute on save to prevent crashes
      vim.g.db_ui_execute_on_save = 0
    end,
  },

  -- vim-dadbod-completion: Database-aware completion
  {
    "kristijanhusak/vim-dadbod-completion",
    dependencies = { "hrsh7th/nvim-cmp" },
    ft = { "sql", "mysql", "plsql" },
    init = function()
      -- Add dadbod completion source to nvim-cmp
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          local cmp = require("cmp")
          local sources = vim.tbl_map(function(source)
            return { name = source.name }
          end, cmp.get_config().sources)

          table.insert(sources, { name = "vim-dadbod-completion" })
          cmp.setup.buffer({ sources = sources })
        end,
      })
    end,
  },

  -- Treesitter: SQL syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "sql" })
      end
    end,
  },

  -- Mason: Install SQL tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "sqlfluff", -- SQL linter and formatter
        "sqls",     -- SQL language server
      })
    end,
  },

  -- nvim-lspconfig: SQL LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sqls = {
          on_attach = function(client, bufnr)
            -- Disable sqls formatting in favor of sqlfluff
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end,
          settings = {
            sqls = {
              connections = {
                -- SQLite connection example
                {
                  driver = "sqlite3",
                  dataSourceName = vim.fn.expand("~") .. "/.local/share/sqlite/local.db",
                },
                -- PostgreSQL connection example (uncomment and configure)
                -- {
                --   driver = "postgresql",
                --   dataSourceName = "host=localhost port=5432 user=postgres password=postgres dbname=postgres sslmode=disable",
                -- },
              },
            },
          },
        },
      },
    },
  },

  -- conform.nvim: SQL formatting with sqlfluff
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

  -- nvim-lint: SQL linting with sqlfluff
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sql = { "sqlfluff" },
      },
    },
  },
}

--- ===========================================================================
--- SQL (database UI) + CSV
--- ===========================================================================
--- Two data-shaped tools sharing a file: vim-dadbod for talking to actual
--- databases, csvview.nvim for browsing flat files that look like tables.
---
--- ---------------------------------------------------------------------------
--- CONNECTION STRINGS (preserved from the deleted SQL_SETUP.md)
--- ---------------------------------------------------------------------------
--- SQLite:     sqlite:/absolute/path/to/database.db
---             sqlite:~/relative/path/to/database.db
--- PostgreSQL: postgresql://user:password@host:5432/dbname
---             postgresql://postgres:postgres@localhost:5432/postgres  (local default)
---
--- ---------------------------------------------------------------------------
--- THREE WAYS TO DECLARE A CONNECTION
--- ---------------------------------------------------------------------------
--- 1. DBUI interactive: <leader>D to open, then `A` to add a connection and
---    paste a connection string. Saved automatically -- best for one-off/
---    exploratory connections.
--- 2. `vim.g.dbs` in core/options.lua (or wherever global options live):
---      vim.g.dbs = {
---        sqlite_local = "sqlite:" .. vim.fn.expand("~") .. "/.local/share/sqlite/local.db",
---        postgres_dev = "postgresql://postgres:password@localhost:5432/mydb",
---      }
---    Best for connections you always want available, on every project.
--- 3. Per-project `.lazy.lua` in the project root (gitignore it):
---      vim.g.dbs = { project_db = "sqlite:./database.db" }
---    Best for a connection that only makes sense inside one repo.
---
--- ---------------------------------------------------------------------------
--- DBUI KEY REFERENCE (inside the DBUI window/tree)
--- ---------------------------------------------------------------------------
---   A       Add connection            <Enter>  Open/Edit/Execute
---   S       Execute default query     o        Open in vertical split
---   d       Delete connection/query   R        Rename buffer
---   r       Refresh
--- ===========================================================================

return {
  --- -------------------------------------------------------------------------
  --- vim-dadbod + vim-dadbod-ui: the database connection and its explorer UI
  --- -------------------------------------------------------------------------
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
      vim.g.db_ui_execute_on_save = false --  don't run a query just because you saved the buffer
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui_queries"
      vim.g.db_ui_use_nvim_notify = true

      --- Keep the builtin SQL omnifunc out of the way of blink.cmp -- without
      --- this it competes for the same completion popup that
      --- vim-dadbod-completion (below) is supposed to own.
      vim.g.omni_sql_default_compl_type = "syntax"
      vim.g.loaded_sql_completion = true
    end,
  },

  --- -------------------------------------------------------------------------
  --- vim-dadbod-completion -- table/column-aware completion
  --- -------------------------------------------------------------------------
  --- CRITICAL FIX: the old config registered this as an `hrsh7th/nvim-cmp`
  --- source (`cmp.setup.buffer({ sources = ... })`). That code was DEAD --
  --- this config runs `saghen/blink.cmp` (see plugins/lsp.lua), and nvim-cmp
  --- was never installed as a plugin at all, so that FileType autocmd fired
  --- and did nothing every single time a .sql buffer opened. Registered
  --- correctly here as a blink source instead, contributed to blink.cmp's
  --- shared `opts.sources.default` list (same contract as nvim-lspconfig's
  --- opts.servers -- see plugins/lsp.lua) via the function-form + list-extend
  --- pattern, since a plain-table opts here would let this list silently
  --- REPLACE the base `{ "lsp", "path", "snippets", "buffer" }` set instead
  --- of adding to it.
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

  --- -------------------------------------------------------------------------
  --- conform.nvim + nvim-lint: sqlfluff for both formatting and linting
  --- -------------------------------------------------------------------------
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

  --- -------------------------------------------------------------------------
  --- Mason: sqlfluff is the only tool here that isn't an LSP server (no `sqls`
  --- server is configured in this file -- sqlfluff covers format + lint, and
  --- vim-dadbod-completion covers completion, so there's nothing left for an
  --- LSP server to usefully own).
  --- -------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "sqlfluff" })
      return opts
    end,
  },

  --- -------------------------------------------------------------------------
  --- csvview.nvim -- CSV/TSV as an actual aligned table, not a wall of commas
  --- -------------------------------------------------------------------------
  --- KEYS MOVED: <leader>C*, not <leader>c*. In the old config these sat
  --- inside the LSP "code" group (<leader>ct/ci/ce/cd), and <leader>cd
  --- collided outright with the global line-diagnostics map set in
  --- util/lsp.lua's LspAttach hook. <leader>C is its own registered group
  --- ("csv", see keymap-tree.lua) specifically to give this plugin room that
  --- doesn't collide with anything LSP-owned.
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
        sticky_header = { enabled = true, separator = "\u{2500}" }, -- BOX DRAWINGS LIGHT HORIZONTAL
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
        callback = function()
          vim.cmd("CsvViewEnable")
        end,
        desc = "Auto-enable CSV view for CSV/TSV files",
      })

      --- Window-local settings while CsvView is active: no soft wrap (would
      --- break column alignment) and a cursor column to track the active
      --- field visually. Reset the cursor column back off on detach.
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

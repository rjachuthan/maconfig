--- ===========================================================================
--- WEB (JS/TS + JSON/YAML/TOML)
--- ===========================================================================
--- "A little bit of JS/TS" -- kept deliberately LEAN. This is not a full
--- frontend setup.
---
--- REMOVED, DELIBERATELY: Angular, Tailwind CSS and Typst support all
--- existed in the old config and are GONE. None of them came from a
--- conscious choice -- they were LazyVim extras enabled by default, and the
--- user never actually used any of the three. Two dependent plugins went
--- with them:
---   - NvChad/nvim-colorizer.lua (inline colour swatches -- existed purely
---     to preview Tailwind's colour classes)
---   - roobert/tailwindcss-colorizer-cmp.nvim -- and this one was ALREADY
---     dead code before removal: it patched `hrsh7th/nvim-cmp`'s formatter,
---     but this config runs `saghen/blink.cmp` (see plugins/lsp.lua), so
---     nvim-cmp was never installed and that plugin's config function never
---     ran. Removing it deletes zero working behaviour.
--- If any of the three come back, they're a new, deliberate addition -- not
--- a "restore what was there".
--- ===========================================================================

return {
  --- -------------------------------------------------------------------------
  --- LSP: vtsls (TS/JS), eslint, jsonls + yamlls (schema-aware), taplo (TOML)
  --- -------------------------------------------------------------------------
  --- vtsls over ts_ls: it wraps the same TypeScript language service but
  --- behaves better under LSP multiplexing (multiple clients/buffers) and is
  --- what the ecosystem has been converging on since ts_ls's maintenance
  --- slowed down.
  ---
  --- jsonls/yamlls both point at SchemaStore's catalogue (b0o/SchemaStore.nvim,
  --- declared as a dependency in plugins/lsp.lua -- just `require`d here) so
  --- `package.json`, `tsconfig.json`, GitHub Actions YAML, etc. all get
  --- real schema validation and completion instead of freeform JSON/YAML.
  --- NOTE the `opts` FUNCTION form below. It is not stylistic -- it is what
  --- keeps SchemaStore lazy.
  ---
  --- A plain `opts = { ... }` table is evaluated when lazy.nvim IMPORTS this
  --- spec, which happens during startup. Any `require()` inside it therefore
  --- loads that plugin eagerly, no matter what its own spec says. Written as a
  --- table, the two `require("schemastore")` calls below pulled a ~2MB schema
  --- catalogue into memory on every launch, including when opening a Python
  --- file. The function form defers evaluation until nvim-lspconfig actually
  --- loads (on LazyFile), so SchemaStore is only paid for when a real file is
  --- open -- and its own spec keeps it off the startup path entirely.
  ---
  --- Same trap applies to any `require()` in an opts table anywhere else.
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local schemastore = require("schemastore")
      opts.servers = opts.servers or {}
      opts.servers.vtsls = {}
      opts.servers.eslint = {}
      opts.servers.taplo = {}
      opts.servers.jsonls = {
        settings = {
          json = {
            schemas = schemastore.json.schemas(),
            validate = { enable = true },
          },
        },
      }
      opts.servers.yamlls = {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = "" }, --  using SchemaStore.nvim instead
            schemas = schemastore.yaml.schemas(),
          },
        },
      }
      return opts
    end,
  },

  --- -------------------------------------------------------------------------
  --- Mason: prettier is the only tool here that isn't an LSP server (and so
  --- isn't auto-installed by mason-lspconfig just from appearing above).
  --- -------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "prettier" })
      return opts
    end,
  },

  --- -------------------------------------------------------------------------
  --- conform.nvim: prettier across the web filetypes
  --- -------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- nvim-ts-autotag: auto-rename/close matching JSX/HTML tags
  --- -------------------------------------------------------------------------
  --- `event = "LazyFile"` -- the old config gave this no trigger at all,
  --- which loaded it at startup for every filetype. It only ever does
  --- anything in markup buffers, so any real-file event is enough; there's
  --- no need for it to specifically watch treesitter attach.
  {
    "windwp/nvim-ts-autotag",
    event = "LazyFile",
    opts = {},
  },

  --- -------------------------------------------------------------------------
  --- neotest-vitest -- contributed to test.lua's shared adapters list
  --- -------------------------------------------------------------------------
  --- See python.lua's neotest-python entry for the full explanation of this
  --- `{ [require_path] = config }` shape -- same contract, same reasoning.
  {
    "nvim-neotest/neotest",
    dependencies = { "marilari88/neotest-vitest" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, { ["neotest-vitest"] = {} })
      return opts
    end,
  },
}

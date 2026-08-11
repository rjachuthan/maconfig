return {
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
            schemaStore = { enable = false, url = "" },
            schemas = schemastore.yaml.schemas(),
          },
        },
      }
      return opts
    end,
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "prettier" })
      return opts
    end,
  },

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

  {
    "windwp/nvim-ts-autotag",
    event = "LazyFile",
    opts = {},
  },

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

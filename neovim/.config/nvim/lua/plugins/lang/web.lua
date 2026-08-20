return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local schemastore = require("schemastore")
      opts.servers = opts.servers or {}
      opts.servers.vtsls = {}
      opts.servers.eslint = {}
      opts.servers.taplo = {}
      -- lspconfig's cmd prefers node_modules/.bin/tailwindcss-language-server
      -- when the project has one, so per-project Tailwind versions win over
      -- the Mason copy.
      opts.servers.tailwindcss = {}
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
      vim.list_extend(opts.ensure_installed, { "prettier", "tailwindcss-language-server" })
      return opts
    end,
  },

  --- Inline colour swatches for hex/rgb/hsl, and for Tailwind class names via
  --- the LSP's documentColor -- `bg-sky-500` renders in sky-500.
  {
    "brenoprata10/nvim-highlight-colors",
    event = "LazyFile",
    keys = {
      { "<leader>uC", "<cmd>HighlightColorsToggle<cr>", desc = "Toggle colour swatches" },
    },
    opts = {
      render = "virtual",
      virtual_symbol = "\u{f111}", -- nf-fa-circle
      virtual_symbol_position = "eol",
      enable_hex = true,
      enable_rgb = true,
      enable_hsl = true,
      enable_named_colors = true,
      enable_tailwind = true,
    },
  },

  --- Inline latest/outdated versions in package.json, plus change/delete on
  --- the dependency under the cursor.
  {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    ft = "json",
    keys = {
      -- <leader>P, not <leader>n: that prefix is the notebook group.
      { "<leader>Ps", function() require("package-info").show({ force = true }) end, desc = "Show dependency versions" },
      { "<leader>Ph", function() require("package-info").hide() end, desc = "Hide dependency versions" },
      { "<leader>Pu", function() require("package-info").update() end, desc = "Update dependency" },
      { "<leader>Pd", function() require("package-info").delete() end, desc = "Delete dependency" },
      { "<leader>Pi", function() require("package-info").install() end, desc = "Install new dependency" },
      { "<leader>Pv", function() require("package-info").change_version() end, desc = "Change dependency version" },
    },
    opts = {
      hide_up_to_date = true,
      package_manager = "npm",
    },
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

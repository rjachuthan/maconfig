local platform = require("core.platform")

return {
  {
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    opts = {
      servers = {},
    },
    config = function(_, opts)
      require("util.lsp").setup()

      local servers = vim.tbl_keys(opts.servers)
      table.sort(servers)
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        automatic_enable = false,
      })

      for name, server_opts in pairs(opts.servers) do
        vim.lsp.config(name, server_opts)
        vim.lsp.enable(name)
      end
    end,
  },

  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = {
      { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" },
    },
    opts = {
      ensure_installed = platform.mason_tools({ "stylua", "shfmt" }),
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local registry = require("mason-registry")
      registry.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local ok, pkg = pcall(registry.get_package, tool)
          if ok and not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
  },

  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
  },

  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "enter", ["<C-y>"] = { "select_and_accept" } },
      completion = {
        menu = {
          draw = {
            components = {
              kind_icon = {
                text = function(ctx) return ctx.kind_icon end,
              },
            },
          },
        },
      },
      appearance = {
        kind_icons = {},
      },
      snippets = { preset = "default" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },

  {
    "stevearc/conform.nvim",
    event = "LazyFile",
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
      },
    },
    config = function(_, opts)
      local conform = require("conform")
      conform.setup(opts)

      require("util.format").register({
        name = "conform",
        priority = 100,
        resolve = function(buf)
          local ok, formatters = pcall(conform.list_formatters_to_run, buf)
          if not ok or #formatters == 0 then
            return nil
          end
          return {
            format = function(_, format_opts)
              conform.format(vim.tbl_extend("force", { bufnr = buf }, format_opts or {}))
            end,
          }
        end,
      })
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
      linters_by_ft = {},
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft

      local augroup = vim.api.nvim_create_augroup("nvim_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = augroup,
        callback = function()
          lint.try_lint()
        end,
        desc = "Run nvim-lint for the current buffer's filetype",
      })
    end,
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location list (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cS", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP references/definitions (Trouble)" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
    },
    opts = {},
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        "lazy.nvim",
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },

  {
    "b0o/SchemaStore.nvim",
    lazy = true,
  },
}

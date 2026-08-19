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

        -- Data filetypes where buffer-word completion is pure noise: every
        -- cell value in a CSV and every base64 blob in a notebook becomes a
        -- candidate. LSP/path/snippets still apply.
        per_filetype = {
          csv = { "path", "snippets" },
          tsv = { "path", "snippets" },
          ipynb = { "lsp", "path", "snippets" },
          dbout = { "path" },
        },

        providers = {
          buffer = {
            opts = {
              -- Default is every visible buffer. Skip the ones snacks.bigfile
              -- has stripped down -- scanning a 500MB extract for words is
              -- the slowest thing in the completion path.
              get_bufnrs = function()
                return vim.tbl_filter(function(buf)
                  return vim.bo[buf].buftype == "" and not vim.b[buf].bigfile
                end, vim.tbl_map(function(win)
                  return vim.api.nvim_win_get_buf(win)
                end, vim.api.nvim_list_wins()))
              end,
            },
          },
        },
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

      -- Linters that shell out to a slow external process. These run on
      -- read and write only -- never on InsertLeave, where they would mean
      -- a process spawn every time you tap <Esc>. ruff is deliberately not
      -- here: it returns in single-digit milliseconds, so live feedback
      -- while editing Python is worth the spawn.
      slow = { "sqlfluff", "shellcheck", "markdownlint-cli2" },

      -- Coalesce bursts of events (`:wa`, a fast <Esc><Esc>) into one run.
      debounce = 300,
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft

      local slow = {}
      for _, name in ipairs(opts.slow or {}) do
        slow[name] = true
      end

      --- Linters configured for `buf`'s filetype, minus the slow ones when
      --- `fast_only` is set.
      ---@param buf integer
      ---@param fast_only boolean
      ---@return string[]
      local function linters_for(buf, fast_only)
        local names = vim.list_extend({}, lint.linters_by_ft[vim.bo[buf].filetype] or {})
        vim.list_extend(names, lint.linters_by_ft["_"] or {})
        if not fast_only then
          return names
        end
        return vim.tbl_filter(function(name)
          return not slow[name]
        end, names)
      end

      local timer = assert(vim.uv.new_timer())

      ---@param fast_only boolean
      local function try_lint(fast_only)
        local buf = vim.api.nvim_get_current_buf()

        -- Terminals, dashboards, picker previews and quickfix have no file
        -- behind them; the old unguarded version linted all of them.
        if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable then
          return
        end

        -- snacks.bigfile marks buffers it has stripped down. Piping a
        -- multi-hundred-MB extract through an external linter is never
        -- what you wanted.
        if vim.b[buf].bigfile then
          return
        end

        local names = linters_for(buf, fast_only)
        if #names == 0 then
          return
        end

        timer:stop()
        timer:start(
          opts.debounce or 300,
          0,
          vim.schedule_wrap(function()
            -- You may have moved on during the debounce window.
            if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_buf() == buf then
              lint.try_lint(names)
            end
          end)
        )
      end

      local augroup = vim.api.nvim_create_augroup("nvim_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = augroup,
        callback = function()
          try_lint(false)
        end,
        desc = "Run every nvim-lint linter for the current buffer's filetype",
      })
      vim.api.nvim_create_autocmd("InsertLeave", {
        group = augroup,
        callback = function()
          try_lint(true)
        end,
        desc = "Run only the fast nvim-lint linters on leaving insert mode",
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

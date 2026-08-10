--- ===========================================================================
--- LSP
--- ===========================================================================
--- Language servers, completion, formatting and linting -- the language-
--- AGNOSTIC parts only. Per-language server settings (tsserver, basedpyright,
--- lua_ls, ...) belong in plugins/lang/*.lua, which extend the shared table
--- this file exposes. See lua/keymap-tree.lua for who owns <leader>c and
--- <leader>x (this file, via util/lsp.lua and trouble.nvim respectively).
---
--- ---------------------------------------------------------------------------
--- THE `opts.servers` CONTRACT (read this before touching plugins/lang/*.lua)
--- ---------------------------------------------------------------------------
--- nvim-lspconfig's spec below declares `opts = { servers = {} }`, empty on
--- purpose. Each plugins/lang/*.lua file that wants a server enabled returns
--- a spec for `"neovim/nvim-lspconfig"` with its OWN `opts.servers` table,
--- e.g.:
---
---   return {
---     {
---       "neovim/nvim-lspconfig",
---       opts = {
---         servers = {
---           lua_ls = {
---             settings = { Lua = { workspace = { checkThirdParty = false } } },
---           },
---         },
---       },
---     },
---   }
---
--- lazy.nvim deep-merges `opts` tables across every spec targeting the same
--- plugin (that's the whole trick -- no manual table-merging code needed
--- anywhere). This file's `config` function below then iterates the merged
--- `opts.servers` and calls `vim.lsp.config(name, server_opts)` +
--- `vim.lsp.enable(name)` for each one. A server entry with no fields at all
--- (`{}`) still enables that server with nvim-lspconfig's defaults -- useful
--- for servers that need zero configuration.
---
--- Keys inside a server's table map directly onto `vim.lsp.config()`'s shape:
--- `settings`, `filetypes`, `root_markers`, `on_attach`, `capabilities`, etc.
--- `mason-lspconfig` (declared below) turns each server name into the right
--- mason package automatically, so lang files don't separately register
--- anything with mason -- just the `opts.servers` entry is enough.
--- ===========================================================================

local platform = require("core.platform")

return {
  --- -------------------------------------------------------------------------
  --- nvim-lspconfig -- server defaults + wiring
  --- -------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    --- Empty on purpose -- see the contract comment at the top of this file.
    --- Populated by lang files via lazy.nvim's opts merging.
    opts = {
      servers = {},
    },
    config = function(_, opts)
      require("util.lsp").setup()

      --- Collect every server name contributed by this file and the lang
      --- files, then hand the list to mason-lspconfig so the servers actually
      --- get INSTALLED.
      ---
      --- This step is easy to leave out and the failure is silent: without it,
      --- `vim.lsp.config()` / `vim.lsp.enable()` below happily register every
      --- server, but nothing ever downloads them, so no LSP client attaches
      --- and the editor just quietly has no completion or diagnostics.
      --- mason-lspconfig v2 does NOT infer this -- `automatic_enable` only
      --- enables servers already on disk; it never installs.
      ---
      --- `automatic_enable = false` because the loop below enables servers
      --- explicitly. Leaving it on makes mason-lspconfig enable them a second
      --- time with different (default) settings, silently discarding the
      --- per-server config from plugins/lang/*.lua.
      local servers = vim.tbl_keys(opts.servers)
      table.sort(servers) --  stable install order, nicer :Mason output
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

  --- -------------------------------------------------------------------------
  --- mason.nvim -- installs LSP servers/tools/linters/formatters
  --- -------------------------------------------------------------------------
  --- `ensure_installed` here is LANGUAGE-AGNOSTIC tools only: stylua (lua
  --- formatter, needed even for editing this config) and shfmt (shell
  --- formatter). Per-language tools (ruff, ts_ls, ...) are installed by
  --- mason-lspconfig automatically for anything in `opts.servers`, or added
  --- to this list by the owning lang file for anything that isn't itself an
  --- LSP server (e.g. a standalone linter).
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

  --- -------------------------------------------------------------------------
  --- mason-lspconfig.nvim -- maps lspconfig server names to mason package
  --- names (e.g. `lua_ls` -> `lua-language-server`) so servers can be
  --- installed by the name you actually write in `opts.servers`.
  --- -------------------------------------------------------------------------
  --- Deliberately NO `opts`/`config` here. Its `setup()` is called from
  --- nvim-lspconfig's `config` above instead, because that is the only place
  --- where the fully-merged `opts.servers` list exists -- lang files
  --- contribute to it, and lazy.nvim has not finished merging their opts at
  --- the time this spec would run. Setting it up here would install only the
  --- servers known at this moment, which is none of them.
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
  },

  --- -------------------------------------------------------------------------
  --- blink.cmp -- completion engine
  --- -------------------------------------------------------------------------
  --- THE completion engine here, not nvim-cmp. The old config still had dead
  --- nvim-cmp source registration in sql.lua and tailwind.lua that never
  --- actually ran (nvim-cmp itself was never installed as a plugin) -- this
  --- is the one, real, live completion engine. `version = "*"` because
  --- blink.cmp ships prebuilt Rust binaries for the fuzzy matcher; no local
  --- build step needed.
  ---
  --- `opts.sources.default` is exposed the same way `opts.servers` is above
  --- so lang files can append to it (e.g. plugins/lang/sql.lua adding
  --- "dadbod" once vim-dadbod-completion is in the mix).
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "*",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = { preset = "enter", ["<C-y>"] = { "select_and_accept" } },
      completion = {
        --- Icons come from mini.icons (plugins/ui.lua), not a hand-rolled
        --- table here -- same reasoning as core/icons.lua's note about LSP
        --- kind glyphs: one maintained source, not a second copy to drift.
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
        kind_icons = {}, -- left to mini.icons; see comment above
      },
      snippets = { preset = "default" },
      sources = {
        --- Language files append to this list (e.g. "dadbod") via opts
        --- merging, same contract as nvim-lspconfig's opts.servers above.
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- conform.nvim -- formatters
  --- -------------------------------------------------------------------------
  --- Registers into util/format.lua as the priority-100 formatter source.
  ---
  --- DO NOT set `format_on_save` here. conform ships that option, but
  --- util/format.lua owns format-on-save (its own BufWritePre hook, gated on
  --- vim.g.autoformat / vim.b.autoformat) so the toggle keymaps and buffer
  --- overrides in that module actually work. Setting conform's own
  --- format_on_save here would run formatting TWICE and ignore the toggle
  --- entirely -- this is the single most likely thing for a future reader to
  --- "helpfully" re-add. Don't.
  {
    "stevearc/conform.nvim",
    event = "LazyFile",
    cmd = "ConformInfo",
    opts = {
      --- Language-agnostic only; lang files append their own via opts merging.
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

  --- -------------------------------------------------------------------------
  --- nvim-lint -- linters that aren't LSP servers (eslint_d, shellcheck, ...)
  --- -------------------------------------------------------------------------
  --- `linters_by_ft` starts empty-ish; lang files populate it the same way
  --- they populate nvim-lspconfig's `opts.servers`.
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

  --- -------------------------------------------------------------------------
  --- trouble.nvim -- diagnostics / references / symbols / todo lists
  --- -------------------------------------------------------------------------
  --- Owns <leader>x (diagnostics) entirely, plus a couple of <leader>c
  --- entries that are naturally "trouble views of LSP data" rather than
  --- direct LSP actions (those live in util/lsp.lua instead).
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
      --- Owned nominally by the todo-comments agent's plugin, but bound here
      --- per that agent's brief -- these are Trouble VIEWS of todo-comments'
      --- data, same pattern as the symbols/lsp entries above.
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
    },
    opts = {},
  },

  --- -------------------------------------------------------------------------
  --- lazydev.nvim -- completion/type info for editing THIS config
  --- -------------------------------------------------------------------------
  --- Makes `vim.*`, lazy.nvim plugin specs, and snacks' API complete and
  --- type-check properly when editing files under this repo's lua/.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Loaded only for files under this config, not every Lua file
        -- anywhere -- keeps it from firing inside random project scripts.
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        "lazy.nvim",
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- SchemaStore.nvim -- JSON/YAML schema catalogue
  --- -------------------------------------------------------------------------
  --- Pure data, no setup/commands of its own -- `lazy = true` with no
  --- trigger means it installs but stays dormant until something
  --- `require`s it directly. That "something" is plugins/lang/web.lua's
  --- jsonls/yamlls server config, which reads SchemaStore's catalogue for
  --- schema URLs. Declared here because it's a language-agnostic dependency,
  --- not because this file uses it.
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
  },
}

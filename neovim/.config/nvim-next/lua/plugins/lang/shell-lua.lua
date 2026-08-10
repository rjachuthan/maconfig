--- ===========================================================================
--- SHELL + LUA
--- ===========================================================================
--- Two small languages sharing one file because neither needs much: shell
--- scripting (bash/zsh, this whole dotfiles repo is full of it) and Lua
--- (this config itself is Lua). Good Lua support in particular is what makes
--- editing THIS config pleasant to work in day to day -- it is not a
--- "nice to have", it's the thing that makes the other five files in this
--- directory tolerable to write and maintain.
--- ===========================================================================

local platform = require("core.platform")

return {
  --- -------------------------------------------------------------------------
  --- bashls (sh/bash/zsh) + lua_ls (Lua)
  --- -------------------------------------------------------------------------
  --- NOTE on lua_ls: folke/lazydev.nvim is already declared in plugins/lsp.lua
  --- (`ft = "lua"`) and gives lua_ls proper `vim.*` / plugin-API completion
  --- for files under this config's runtimepath. Don't redeclare it here --
  --- this spec only adds the server itself.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
        },
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              --- lazydev.nvim (plugins/lsp.lua) hides the global `vim` warning
              --- for config files; this quiets it as a fallback for any Lua
              --- buffer lazydev's `ft`/library filter doesn't reach.
              diagnostics = { globals = { "vim" } },
            },
          },
        },
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- Mason: shellcheck (lint) + shfmt (format), routed through
  --- platform.mason_tools() -- neither has a Windows build, and asking mason
  --- to install them there just produces a noisy failure on every startup.
  --- -------------------------------------------------------------------------
  --- NOTE: stylua and shfmt are ALREADY in the base mason list in
  --- plugins/lsp.lua -- only shellcheck is actually new here. shfmt is listed
  --- again below anyway so this file is self-documenting about what shell
  --- support needs, but `vim.list_extend` + mason's own dedup on install
  --- means listing it twice costs nothing.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, platform.mason_tools({ "shellcheck", "shfmt" }))
      return opts
    end,
  },

  --- -------------------------------------------------------------------------
  --- conform.nvim: stylua for Lua
  --- -------------------------------------------------------------------------
  --- shfmt for sh/bash is ALREADY wired in plugins/lsp.lua's base conform
  --- spec (formatters_by_ft.sh / .bash), so it is not repeated here.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- nvim-lint: shellcheck for sh/bash/zsh
  --- -------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
      },
    },
  },
}

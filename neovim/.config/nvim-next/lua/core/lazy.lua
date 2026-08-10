--- ===========================================================================
--- PLUGIN MANAGER (lazy.nvim)
--- ===========================================================================
--- Bootstraps lazy.nvim and defines the loading policy for the whole config.
---
--- THE RULE: nothing loads at startup unless it must draw pixels on the first
--- frame. Everything else waits for an event, a filetype, a command or a key.
---
--- Verify it holds with `:Lazy profile` -- if something is loading at startup
--- that isn't in the short eager list below, that's a bug worth fixing.
---
--- Why lazy.nvim and not vim.pack? Neovim 0.12's built-in vim.pack installs
--- and :packadd's immediately -- it has no event/ft/cmd/keys triggers, no
--- dependency ordering, no build hooks and no profiler. Since lazy loading is
--- the whole point of this config, lazy.nvim stays.
--- ===========================================================================

--- ---------------------------------------------------------------------------
--- Bootstrap: clone lazy.nvim on first run
--- ---------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

--- ---------------------------------------------------------------------------
--- The `LazyFile` event
--- ---------------------------------------------------------------------------
--- A custom event meaning "a real file was opened". Plugins that only matter
--- once you're editing an actual file -- treesitter, gitsigns, nvim-lint --
--- use `event = "LazyFile"` and stay unloaded on the dashboard.
---
--- This is NOT built into lazy.nvim; it was a LazyVim invention. Any spec
--- copied from LazyVim that says `event = "LazyFile"` will silently never load
--- without the code below, which is exactly the kind of bug that's miserable
--- to track down. Hence: defined explicitly, right here.
---
--- It fires on BufReadPost/BufNewFile/BufWritePre, but only for buffers backed
--- by a real path -- not the dashboard, not a terminal, not a help window.
local Event = require("lazy.core.handler.event")
Event.mappings.LazyFile = {
  id = "LazyFile",
  event = { "BufReadPost", "BufNewFile", "BufWritePre" },
}
Event.mappings["User LazyFile"] = Event.mappings.LazyFile

--- ---------------------------------------------------------------------------
--- Setup
--- ---------------------------------------------------------------------------
require("lazy").setup({
  spec = {
    --- Each of these is a module returning a list of plugin specs. Grouped by
    --- role rather than by plugin so related things stay together.
    { import = "plugins.ui" }, --  colourscheme, statusline, tabs, cmdline
    { import = "plugins.editor" }, --  treesitter, textobjects, motions
    { import = "plugins.lsp" }, --  lsp, completion, format, lint
    { import = "plugins.git" }, --  gitsigns, diffview, lazygit
    { import = "plugins.debug" }, --  dap
    { import = "plugins.test" }, --  neotest
    { import = "plugins.tools" }, --  terminal, ai, tmux
    { import = "plugins.lang" }, --  per-language: python, web, sql, ...
  },

  defaults = {
    --- Custom plugins do NOT load eagerly. Every spec must justify when it
    --- loads by declaring event / ft / cmd / keys, or explicitly opt in with
    --- `lazy = false`. This is the single most important line in this file.
    lazy = true,
    --- Track the latest commit rather than semver tags -- too many Neovim
    --- plugins have stale releases for `version = "*"` to be safe.
    version = false,
  },

  --- Colourscheme used while plugins are being installed on first run.
  install = { colorscheme = { "koda", "habamax" } },

  --- Don't auto-check for updates. It fires a background git process for every
  --- plugin; run `:Lazy update` deliberately instead, and commit the resulting
  --- lazy-lock.json so both machines stay in sync.
  checker = { enabled = false },
  change_detection = { enabled = true, notify = false },

  ui = { border = "rounded" },

  performance = {
    rtp = {
      --- Built-in Vim plugins we never use. Each one skipped is a few ms and
      --- a few unwanted autocmds. netrw goes because snacks.explorer is the
      --- file browser here.
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "rplugin",
      },
    },
  },
})

--- ---------------------------------------------------------------------------
--- `:Lazy` on <leader>l -- set here rather than in keymap-tree.lua because the
--- manager itself is always available and has no plugin to lazy-load.
--- ---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy (plugin manager)" })

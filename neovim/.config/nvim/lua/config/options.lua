-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.winbar = "%=%m %f"

-- Swap file handling: disable swap files to prevent E325 errors
-- Modern Neovim with auto-save and version control doesn't need swap files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Alternative: if you want to keep swap files, use these instead:
-- vim.opt.swapfile = true
-- vim.opt.directory = vim.fn.stdpath("state") .. "/swap//"
-- vim.opt.shortmess:append("A")  -- Don't show swap file warning

-- Python configuration
-- LSP: "pyright" (default) or "basedpyright"
vim.g.lazyvim_python_lsp = "pyright"
-- Linter: "ruff" (recommended)
vim.g.lazyvim_python_ruff = "ruff"

-- Database connections for vim-dadbod
-- SQLite example: sqlite:path/to/database.db
-- PostgreSQL example: postgresql://user:password@localhost:5432/dbname
vim.g.dbs = {
  -- Example SQLite connection (update path as needed)
  -- sqlite_local = "sqlite:" .. vim.fn.expand("~") .. "/.local/share/sqlite/local.db",

  -- Example PostgreSQL connection (update credentials as needed)
  -- postgres_local = "postgresql://postgres:postgres@localhost:5432/postgres",
}

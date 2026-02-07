# SQL Support in Neovim

## Overview

SQL support is now configured in your Neovim setup with support for SQLite and PostgreSQL databases.

## What's Installed

### Plugins

- **vim-dadbod**: Core database interface (`:DB` command)
- **vim-dadbod-ui**: Visual database explorer (`:DBUI` or `<leader>D`)
- **vim-dadbod-completion**: Database-aware autocompletion
- **sqls**: SQL language server for intellisense
- **sqlfluff**: SQL linter and formatter

### Features

- SQL syntax highlighting via Treesitter
- Database autocompletion (tables, columns, keywords)
- Visual database browser
- SQL formatting and linting
- LSP support for go-to-definition, hover, etc.

## Quick Start

### 1. Open Database UI

Press `<leader>D` (in normal mode) or run `:DBUI`

### 2. Add Database Connection

In the DBUI window:

- Press `A` to add a connection
- Enter connection string:
  - SQLite: `sqlite:/path/to/database.db`
  - PostgreSQL: `postgresql://user:password@host:5432/dbname`

### 3. Test SQLite Connection

A test database has been created at `~/.local/share/sqlite/local.db`

To connect:
1. Open DBUI (`<leader>D`)
2. Add connection: `sqlite:~/.local/share/sqlite/local.db`
3. Navigate the tree to see the `test` table
4. Press `<Enter>` on a table to view its structure
5. Press `S` to select data from the table

## Database Connections

### Method 1: DBUI Interface (Recommended for testing)

Use the DBUI interface to add connections interactively. Connections are saved automatically.

### Method 2: Configuration File (Recommended for permanent connections)

Edit `~/.config/nvim/lua/config/options.lua` and update the `vim.g.dbs` table:

```lua
vim.g.dbs = {
  sqlite_local = "sqlite:" .. vim.fn.expand("~") .. "/.local/share/sqlite/local.db",
  postgres_dev = "postgresql://postgres:password@localhost:5432/mydb",
}
```

### Method 3: Project-specific (Recommended for project databases)

Create `.lazy.lua` in your project root (add to `.gitignore`):

```lua
vim.g.dbs = {
  project_db = "sqlite:./database.db",
}
```

## Connection String Formats

### SQLite

```
sqlite:/absolute/path/to/database.db
sqlite:~/relative/path/to/database.db
```

### PostgreSQL

```
postgresql://username:password@hostname:5432/database_name
```

Common localhost example:
```
postgresql://postgres:postgres@localhost:5432/postgres
```

## Usage

### DBUI Keybindings

| Key | Action |
|-----|--------|
| `<leader>D` | Toggle DBUI |
| `A` | Add connection |
| `S` | Execute default query for item |
| `<Enter>` | Open/Edit/Execute |
| `o` | Open in vertical split |
| `d` | Delete connection/query |
| `R` | Rename buffer |
| `r` | Refresh |

### Writing SQL Queries

1. Create a new `.sql` file or use DBUI to create a query
2. Write your SQL query
3. Visual select the query (or entire buffer)
4. Press `<leader>S` to execute (or use `:DB {connection}` command)

### Autocompletion

When writing SQL:
- Tables, columns, and keywords will autocomplete
- Use `<C-Space>` to trigger completion manually
- Works with vim-dadbod-completion in SQL files

### Formatting

- Format SQL: `:Format` or save with auto-format enabled
- Uses sqlfluff with ANSI dialect

## LSP Configuration

The `sqls` language server is configured with default SQLite connection at:
```
~/.local/share/sqlite/local.db
```

To add more LSP connections, edit `~/.config/nvim/lua/plugins/sql.lua` in the `sqls` settings section.

## Testing Your Setup

1. Open Neovim
2. Run `:checkhealth lazy` to verify plugins loaded
3. Run `:Mason` to verify sqlfluff and sqls are installed
4. Press `<leader>D` to open DBUI
5. Add connection: `sqlite:~/.local/share/sqlite/local.db`
6. Navigate to the `test` table and press `S` to query it

## PostgreSQL Setup (Optional)

To set up PostgreSQL:

1. Install PostgreSQL:
   ```bash
   brew install postgresql@15
   brew services start postgresql@15
   ```

2. Create a test database:
   ```bash
   createdb testdb
   ```

3. Add connection in DBUI or options.lua:
   ```
   postgresql://$(whoami)@localhost:5432/testdb
   ```

## Troubleshooting

### "sqls not found"
Run `:Mason` and ensure `sqls` is installed. If not, select it and press `i` to install.

### "sqlfluff not found"
Run `:Mason` and ensure `sqlfluff` is installed.

### Database connection fails
- Check connection string format
- For PostgreSQL: verify server is running (`brew services list`)
- For SQLite: verify file path is correct and accessible

### No autocompletion
- Ensure file type is detected as SQL (`:set ft?` should show `filetype=sql`)
- Check that vim-dadbod-completion is loaded (`:Lazy`)

## Resources

- [vim-dadbod documentation](https://github.com/tpope/vim-dadbod)
- [vim-dadbod-ui documentation](https://github.com/kristijanhusak/vim-dadbod-ui)
- [LazyVim SQL extras](https://www.lazyvim.org/extras/lang/sql)

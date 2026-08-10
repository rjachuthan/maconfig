--- ===========================================================================
--- AUTOCMDS
--- ===========================================================================
--- Each autocmd gets its own named augroup so it can be individually disabled:
---   vim.api.nvim_del_augroup_by_name("nvim_wrap_spell")
---
--- These are ported from LazyVim's defaults plus the three from the old
--- config. Two things from the old config are deliberately NOT here:
---   * restore_cursor  -- duplicated LazyVim's last_loc; merged into one below
---   * auto_lint       -- ran `npm run lint` (a full npm process!) on every
---                        .ts save. nvim-lint already covers this, per-buffer
---                        and async. See plugins/lsp.lua.
--- ===========================================================================

---@param name string
---@return integer
local function augroup(name)
  return vim.api.nvim_create_augroup("nvim_" .. name, { clear = true })
end

local autocmd = vim.api.nvim_create_autocmd

--- ---------------------------------------------------------------------------
--- Reload files changed outside Neovim
--- Matters constantly here: git checkout, a formatter run in another terminal,
--- Claude Code editing a file you have open.
--- ---------------------------------------------------------------------------
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
  desc = "Reload buffer if the file changed on disk",
})

--- ---------------------------------------------------------------------------
--- Flash yanked text
--- Cheap visual confirmation that y actually grabbed what you meant.
--- ---------------------------------------------------------------------------
autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.hl.on_yank()
  end,
  desc = "Briefly highlight yanked text",
})

--- ---------------------------------------------------------------------------
--- Rebalance splits when the terminal is resized
--- ---------------------------------------------------------------------------
autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
  desc = "Equalize split sizes on terminal resize",
})

--- ---------------------------------------------------------------------------
--- Restore cursor to last position when reopening a file
--- Guarded with a buffer variable so it only fires once per buffer -- without
--- that, reloading a file yanks you back to the old position mid-edit.
--- ---------------------------------------------------------------------------
autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit", "gitrebase", "hgcommit", "svn" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
      return
    end
    vim.b[buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local line_count = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = "Restore cursor to last known position",
})

--- ---------------------------------------------------------------------------
--- Close throwaway windows with q
--- Anything in this list is a tool window, not a document -- q should dismiss
--- it, the way it does in :help. Add filetypes here as you meet them.
--- ---------------------------------------------------------------------------
autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "checkhealth",
    "dap-float",
    "dbout", --  vim-dadbod query output
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "notify",
    "qf",
    "query", --  treesitter playground
    "snacks_win",
    "startuptime",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false --  keep it out of :bnext rotation
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, { buffer = event.buf, silent = true, desc = "Close window" })
    end)
  end,
  desc = "Map q to close tool windows",
})

--- ---------------------------------------------------------------------------
--- Prose filetypes: wrap and spellcheck
--- ---------------------------------------------------------------------------
autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
  desc = "Enable wrap and spellcheck for prose",
})

--- ---------------------------------------------------------------------------
--- Don't conceal quotes in JSON
--- conceallevel=2 is set globally for markdown/obsidian, but in JSON it hides
--- the quote characters, which is actively confusing.
--- ---------------------------------------------------------------------------
autocmd("FileType", {
  group = augroup("json_conceal"),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
  desc = "Disable concealing in JSON",
})

--- ---------------------------------------------------------------------------
--- Create missing parent directories on save
--- Lets you `:e src/new/deep/file.py` and just write it.
--- ---------------------------------------------------------------------------
autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return --  a URL-ish buffer (oil://, fugitive://); nothing to create
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
  desc = "Create parent directories when saving a new file",
})

--- ---------------------------------------------------------------------------
--- Make shell scripts executable on save
--- Ported from the old config. Only touches files that start with a shebang,
--- which is stricter (and safer) than the old pattern-based version -- that
--- one chmod'd every *.sh whether or not it was meant to be run directly.
--- ---------------------------------------------------------------------------
autocmd("BufWritePost", {
  group = augroup("auto_chmod"),
  pattern = { "*.sh", "*.bash", "*.zsh" },
  callback = function(event)
    local platform = require("core.platform")
    if platform.is_win then
      return --  no executable bit on NTFS; nothing to do
    end
    local first_line = vim.api.nvim_buf_get_lines(event.buf, 0, 1, false)[1] or ""
    if first_line:match("^#!") and vim.fn.filereadable(event.file) == 1 then
      vim.fn.setfperm(event.file, "rwxr-xr-x")
    end
  end,
  desc = "chmod +x scripts with a shebang",
})

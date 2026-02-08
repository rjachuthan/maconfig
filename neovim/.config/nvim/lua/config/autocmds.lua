-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- ============================================================================
-- Auto-executable files
-- ============================================================================
-- Automatically make script files executable after saving.
-- This is useful for scripts that should be executable but might not have
-- the executable bit set during creation.
--
-- To add more file types, simply add patterns to the executable_patterns table.
-- ============================================================================

local executable_patterns = {
  "*.sh", -- Shell scripts
  -- Add more patterns here as needed:
  -- "*.bash",
  -- "*.zsh",
  -- "*.py",
  -- "*.pl",
  -- "*.rb",
}

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("auto_executable", { clear = true }),
  pattern = executable_patterns,
  callback = function()
    local file = vim.fn.expand("%:p")
    -- Check if file exists and is a regular file (not a directory)
    if vim.fn.filereadable(file) == 1 then
      vim.fn.setfperm(file, "rwxr-xr-x")
    end
  end,
  desc = "Make script files executable after saving",
})

-- ============================================================================
-- Restore cursor position
-- ============================================================================
-- When reopening a file, restore the cursor to the last known position.
-- This uses the `"` mark which stores the position before exiting.
--
-- The autocommand checks if:
-- 1. The mark exists and is within the file bounds
-- 2. The file type is not in the exclude list
-- 3. Not in a git commit message or similar temporary buffer
-- ============================================================================

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("restore_cursor", { clear = true }),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)

    -- Check if mark exists and is within file bounds
    if mark[1] > 0 and mark[1] <= line_count then
      -- Don't restore for certain file types
      local exclude_ft = {
        "gitcommit",
        "gitrebase",
        "svn",
        "hgcommit",
      }

      local filetype = vim.bo.filetype
      if not vim.tbl_contains(exclude_ft, filetype) then
        vim.cmd('normal! g`"')
      end
    end
  end,
  desc = "Restore cursor position when reopening files",
})

-- ============================================================================
-- Auto-lint on save
-- ============================================================================
-- Automatically run linting/formatting commands after saving certain file types.
-- Commands run asynchronously to avoid blocking the editor.
--
-- To add more file types and their lint commands:
-- 1. Add patterns to lint_patterns
-- 2. Add corresponding commands to lint_commands (indexed by file extension)
-- 3. Or add a custom callback for more complex logic
--
-- To disable: Comment out this entire autocmd block
-- ============================================================================

local lint_config = {
  -- Map file extensions to their lint commands
  commands = {
    ts = "npm run lint",
    tsx = "npm run lint",
    -- Add more as needed:
    -- js = "npm run lint",
    -- jsx = "npm run lint",
    -- py = "black %",
    -- go = "gofmt -w %",
  },
  -- Files to match
  patterns = { "*.ts", "*.tsx" },
}

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("auto_lint", { clear = true }),
  pattern = lint_config.patterns,
  callback = function()
    local ext = vim.fn.expand("%:e")
    local cmd = lint_config.commands[ext]

    if cmd then
      -- Check if we're in a project with package.json (for npm commands)
      if cmd:match("^npm") then
        local package_json = vim.fn.findfile("package.json", ".;")
        if package_json == "" then
          return -- No package.json found, skip linting
        end
      end

      -- Run command asynchronously to avoid blocking
      vim.fn.jobstart(cmd, {
        on_exit = function(_, exit_code)
          if exit_code ~= 0 then
            vim.notify("Linting failed (exit code: " .. exit_code .. ")", vim.log.levels.WARN)
          end
        end,
        stdout_buffered = true,
        stderr_buffered = true,
      })
    end
  end,
  desc = "Run linting/formatting on save",
})

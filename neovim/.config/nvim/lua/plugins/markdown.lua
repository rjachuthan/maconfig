return {
  -- nvim-lint: Markdown linting with markdownlint
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      -- Ensure linters_by_ft table exists
      opts.linters_by_ft = opts.linters_by_ft or {}

      -- Add markdownlint for markdown files
      opts.linters_by_ft.markdown = { "markdownlint" }

      return opts
    end,
    config = function(_, opts)
      local lint = require("lint")

      -- Apply linters_by_ft configuration
      lint.linters_by_ft = opts.linters_by_ft or {}

      -- Customize markdownlint to run from the file's directory
      -- This ensures it finds .markdownlint.json in your project root
      lint.linters.markdownlint.cwd = function(params)
        -- Return the directory of the current file
        return vim.fn.fnamemodify(params.bufnr and vim.api.nvim_buf_get_name(params.bufnr) or "", ":h")
      end

      -- Set up autocommands for linting
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}

-- Common markdownlint rules you might want to disable:
-- MD007: Unordered list indentation
-- MD013: Line length limit
-- MD024: Multiple headings with same content
-- MD025: Multiple top-level headings
-- MD026: Trailing punctuation in heading
-- MD029: Ordered list item prefix
-- MD033: Inline HTML
-- MD034: Bare URL without angle brackets
-- MD036: Emphasis used instead of heading
-- MD040: Fenced code blocks should have a language
-- MD041: First line must be top-level heading
-- MD046: Code block style
-- MD047: Files should end with a newline
--
-- Full list: https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md

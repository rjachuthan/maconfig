return {
  -- nvim-lint: Markdown linting with markdownlint
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      -- Ensure linters_by_ft table exists
      opts.linters_by_ft = opts.linters_by_ft or {}

      -- Add markdownlint for markdown files
      opts.linters_by_ft.markdown = { "markdownlint" }

      -- NOTE: You have two options for disabling markdown rules:
      --
      -- OPTION 1 (Recommended): Create a .markdownlint.json file in your project root
      -- Example .markdownlint.json:
      -- {
      --   "MD013": false,  // Line length
      --   "MD033": false,  // Inline HTML
      --   "MD041": false,  // First line heading
      --   "MD034": false   // Bare URLs
      -- }
      --
      -- OPTION 2: Uncomment the code below to disable rules globally in Neovim
      --
      -- local markdownlint = require("lint").linters.markdownlint
      -- markdownlint.args = {
      --   "--disable",
      --   "MD013", -- Line length limit
      --   "MD033", -- Inline HTML
      --   "MD041", -- First line must be top-level heading
      --   "MD034", -- Bare URL without angle brackets
      --   -- Add more rules as needed
      --   "--",
      --   vim.api.nvim_buf_get_name(0),
      -- }

      return opts
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


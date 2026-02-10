return {
  -- nvim-lint: Markdown linting with markdownlint
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      -- Ensure linters_by_ft table exists
      opts.linters_by_ft = opts.linters_by_ft or {}

      -- Add markdownlint for markdown files
      opts.linters_by_ft.markdown = { "markdownlint" }

      -- NOTE: markdownlint-cli automatically searches for config files:
      -- 1. .markdownlint.json, .markdownlint.jsonc, .markdownlintrc in current dir
      -- 2. Searches parent directories up to filesystem root
      -- 3. Falls back to ~/.markdownlint.json
      --
      -- Your project's .markdownlint.json will be respected automatically!

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

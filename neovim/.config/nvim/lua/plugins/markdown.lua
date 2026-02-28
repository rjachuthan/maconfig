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

  -- diagram.nvim: Render diagrams (mermaid, plantuml, d2, etc.) in Neovim
  {
    "3rd/diagram.nvim",
    dependencies = {
      "3rd/image.nvim", -- Required for rendering diagrams as images
    },
    opts = {
      renderer_options = {
        mermaid = {
          background = nil, -- nil for transparent background
          theme = "dark", -- Use "dark" or "default" theme for mermaid
        },
      },
    },
  },

  -- image.nvim: Display images in Neovim (required by diagram.nvim)
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty", -- or "ueberzug" depending on your terminal
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
      },
      max_width = 150, -- Increased from 100
      max_height = 50, -- Increased from 12 to give diagrams more space
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
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

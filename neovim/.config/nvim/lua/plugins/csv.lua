return {
  "hat0uma/csvview.nvim",
  ft = { "csv", "tsv" },
  cmd = {
    "CsvViewEnable",
    "CsvViewDisable",
    "CsvViewToggle",
    "CsvViewInfo",
  },
  opts = {
    parser = {
      -- Delimiter auto-detection with fallback order
      delimiter = {
        default = ",",
        ft = {
          tsv = "\t",
        },
      },

      -- Comment prefix characters
      comments = {
        "#", -- Hash comments
        "//", -- C-style comments
      },

      -- Quote character for multi-line fields
      quote_char = '"',

      -- Async parsing configuration
      async = {
        enable = true,
        chunksize = 50, -- Lines to process per cycle
      },

      -- Maximum lines to look ahead for multi-line fields
      max_lookahead = 50,
    },

    view = {
      -- Column display settings
      min_column_width = 5,
      spacing = 2,

      -- Display mode: "highlight" (highlight delimiters) or "border" (show vertical bars)
      display_mode = "border",

      -- Header configuration
      header = {
        auto = true, -- Auto-detect header line
        lnum = 1, -- Line number of header (if auto = false)
      },

      -- Sticky header (stays visible when scrolling)
      sticky_header = {
        enabled = true,
        separator = "─",
      },
    },

    -- Keymaps for CSV navigation
    keymaps = {
      -- Text objects for fields
      textobject_field_inner = {
        "if",
        mode = { "o", "x" },
        desc = "CSV: Inner field",
      },
      textobject_field_outer = {
        "af",
        mode = { "o", "x" },
        desc = "CSV: Outer field",
      },

      -- Field navigation
      jump_next_field_end = {
        "<Tab>",
        mode = { "n", "v" },
        desc = "CSV: Next field",
      },
      jump_prev_field_end = {
        "<S-Tab>",
        mode = { "n", "v" },
        desc = "CSV: Previous field",
      },

      -- Row navigation
      jump_next_row = {
        "<CR>",
        mode = { "n", "v" },
        desc = "CSV: Next row",
      },
      jump_prev_row = {
        "<S-CR>",
        mode = { "n", "v" },
        desc = "CSV: Previous row",
      },
    },
  },

  config = function(_, opts)
    require("csvview").setup(opts)

    -- Auto-enable CSV view for CSV/TSV files
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "csv", "tsv" },
      callback = function()
        vim.cmd("CsvViewEnable")
      end,
      desc = "Auto-enable CSV view for CSV/TSV files",
    })

    -- Custom event handlers (optional)
    vim.api.nvim_create_autocmd("User", {
      pattern = "CsvViewAttach",
      callback = function(args)
        local bufnr = args.buf
        -- Additional settings when CSV view is enabled
        vim.wo.wrap = false -- Window-local option
        vim.wo.cursorcolumn = true -- Window-local option
      end,
      desc = "CSV view attached",
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "CsvViewDetach",
      callback = function(args)
        local bufnr = args.buf
        -- Reset settings when CSV view is disabled
        vim.wo.cursorcolumn = false
      end,
      desc = "CSV view detached",
    })
  end,

  keys = {
    {
      "<leader>ct",
      "<cmd>CsvViewToggle<cr>",
      desc = "CSV: Toggle view",
      ft = { "csv", "tsv" },
    },
    {
      "<leader>ci",
      "<cmd>CsvViewInfo<cr>",
      desc = "CSV: Show info",
      ft = { "csv", "tsv" },
    },
    {
      "<leader>ce",
      "<cmd>CsvViewEnable<cr>",
      desc = "CSV: Enable view",
      ft = { "csv", "tsv" },
    },
    {
      "<leader>cd",
      "<cmd>CsvViewDisable<cr>",
      desc = "CSV: Disable view",
      ft = { "csv", "tsv" },
    },
  },
}

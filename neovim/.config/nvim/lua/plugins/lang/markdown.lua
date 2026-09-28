local platform = require("core.platform")

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "md" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    keys = {
      {
        "<leader>um",
        function()
          require("render-markdown").toggle()
        end,
        desc = "Toggle markdown rendering",
        ft = { "markdown", "md" },
      },
    },
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { marksman = {} } },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdownlint-cli2" })
      return opts
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = { markdown = { "prettier", "markdownlint-cli2" } },
      formatters = {
        prettier = { prepend_args = { "--prose-wrap", "always" } },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = { linters_by_ft = { markdown = { "markdownlint-cli2" } } },
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    cond = platform.has("node"),
    build = "cd app && npx --yes yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview", ft = "markdown" },
    },
  },
}

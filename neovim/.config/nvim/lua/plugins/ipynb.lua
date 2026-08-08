return {
  -- Modal Jupyter notebook editor
  {
    "ajbucci/ipynb.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "neovim/nvim-lspconfig",
      "nvim-tree/nvim-web-devicons",
      "folke/snacks.nvim",
    },
    opts = {},
    config = function(_, opts)
      -- Windows only: ipynb.nvim's own parser install and nvim-treesitter's main-branch
      -- installer both race to `tree-sitter build` the ipynb grammar to its default output
      -- path on every startup. tree-sitter-cli's default output-path logic is broken on
      -- Windows (it either looks for cl.exe or writes a malformed path), and the race
      -- itself trips Windows' stricter file locking, producing errors either way.
      -- Pre-building once with an explicit -o path sidesteps both: whichever installer
      -- runs first finds the parser already compiled and skips its own attempt.
      if vim.fn.has("win32") == 1 then
        local parser_dir = require("ipynb.util").get_plugin_root() .. "/tree-sitter-ipynb"
        -- nvim-treesitter (main) looks for compiled parsers under its own managed
        -- `site/parser/<lang>.so`, not inside the plugin's source directory.
        local install_parser_dir = vim.fn.stdpath("data") .. "/site/parser"
        local parser_so = install_parser_dir .. "/ipynb.so"
        -- Resolve tree-sitter-cli's mason install path directly rather than relying on
        -- PATH, since mason.nvim may not have prepended its bin dir yet at this point
        -- (ipynb.nvim loads eagerly via lazy = false, ahead of lazy-loaded plugins).
        local ts_cli = vim.fn.stdpath("data") .. "/mason/packages/tree-sitter-cli/tree-sitter.exe"
        if vim.fn.filereadable(parser_so) == 0 and vim.fn.executable(ts_cli) == 1 then
          if vim.fn.executable("cl") == 0 and vim.fn.executable("gcc") == 1 then
            vim.env.CC = vim.env.CC or "gcc"
          end
          vim.fn.mkdir(install_parser_dir, "p")
          vim.fn.system({ ts_cli, "build", "-o", parser_so, parser_dir })
        end
      end

      require("ipynb").setup(opts)
    end,
  },
}

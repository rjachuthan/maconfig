local platform = require("core.platform")

return {
  {
    "ajbucci/ipynb.nvim",
    ft = "ipynb",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "neovim/nvim-lspconfig",
      "nvim-tree/nvim-web-devicons",
      "folke/snacks.nvim",
    },
    opts = {
      keymaps = {
        jump_to_cell = "<leader>nj",
        add_cell_above = "<leader>na",
        add_cell_below = "<leader>nb",
        make_markdown = "<leader>nm",
        make_code = "<leader>ny",
        make_raw = "<leader>nr",
        fold_toggle = "<leader>nf",
        menu_execute_cell = "<leader>nx",
        menu_execute_and_next = "<leader>nX",
        open_output = "<leader>no",
        clear_output = "<leader>nc",
        clear_all_outputs = "<leader>nC",
        kernel_interrupt = "<leader>ni",
        kernel_restart = "<leader>n0",
        kernel_start = "<leader>ns",
        kernel_shutdown = "<leader>nS",
        kernel_info = "<leader>nn",
        variable_inspect = "<leader>nh",
        cell_variables = "<leader>nv",
        toggle_auto_hover = "<leader>nH",
      },
    },
    config = function(_, opts)
      if vim.fn.has("win32") == 1 then
        local parser_dir = require("ipynb.util").get_plugin_root() .. "/tree-sitter-ipynb"
        local install_parser_dir = vim.fn.stdpath("data") .. "/site/parser"
        local parser_so = install_parser_dir .. "/ipynb.so"
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
  {
    "3rd/image.nvim",
    ft = { "markdown", "ipynb" },
    cond = not platform.is_win,
    opts = {
      backend = "kitty",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { "markdown", "vimwiki" },
        },
      },
      max_width = 150,
      max_height = 50,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },
  {
    "3rd/diagram.nvim",
    ft = { "markdown", "ipynb" },
    cond = not platform.is_win,
    dependencies = { "3rd/image.nvim" },
    opts = {
      renderer_options = {
        mermaid = {
          background = nil,
          theme = "dark",
        },
      },
    },
  },
}

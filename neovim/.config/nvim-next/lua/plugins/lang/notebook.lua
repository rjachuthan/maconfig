--- ===========================================================================
--- NOTEBOOK (Jupyter) + IMAGES
--- ===========================================================================
--- ipynb.nvim edits .ipynb files as a modal notebook UI; image.nvim and
--- diagram.nvim render inline images and diagrams (mermaid/plantuml/d2) in
--- markdown and notebook buffers alike.
--- ===========================================================================

local platform = require("core.platform")

return {
  --- -------------------------------------------------------------------------
  --- ipynb.nvim -- Jupyter notebook editing
  --- -------------------------------------------------------------------------
  --- `ft = "ipynb"` -- the old config had `lazy = false`, loading this (and
  --- running its config function, including the Windows workaround below) on
  --- EVERY startup regardless of whether a notebook was ever opened. Fixed
  --- here: it only loads once a .ipynb buffer actually exists.
  {
    "ajbucci/ipynb.nvim",
    ft = "ipynb",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "neovim/nvim-lspconfig",
      "nvim-tree/nvim-web-devicons",
      "folke/snacks.nvim",
    },
    --- ipynb.nvim's OWN defaults put every leader-based binding under
    --- `<leader>k` (jump_to_cell, add_cell_*, execute/output/kernel/inspect
    --- actions -- see its README). `<leader>k` isn't a registered group in
    --- keymap-tree.lua, but `<leader>n` (notebook) IS -- and is this file's
    --- per the ownership table there. Remapping every leader entry from `k`
    --- to `n` here (same trailing letter, just the prefix changes) keeps the
    --- plugin's own bindings, just filed under the group that actually
    --- exists. Mode-local, non-leader keys (`]]`, `[[`, `dd`, `p`, `P`,
    --- `<M-j>`, `<M-k>`, execute via `<C-CR>`/`<S-CR>`/`<M-CR>`) are left at
    --- their defaults -- they don't collide with anything.
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
      --- Windows only: ipynb.nvim's own parser install and nvim-treesitter's
      --- main-branch installer both race to `tree-sitter build` the ipynb
      --- grammar to its default output path on every startup. tree-sitter-
      --- cli's default output-path logic is broken on Windows (it either
      --- looks for cl.exe or writes a malformed path), and the race itself
      --- trips Windows' stricter file locking, producing errors either way.
      --- Pre-building once with an explicit -o path sidesteps both:
      --- whichever installer runs first finds the parser already compiled
      --- and skips its own attempt.
      if vim.fn.has("win32") == 1 then
        local parser_dir = require("ipynb.util").get_plugin_root() .. "/tree-sitter-ipynb"
        -- nvim-treesitter (main) looks for compiled parsers under its own
        -- managed `site/parser/<lang>.so`, not inside the plugin's source
        -- directory.
        local install_parser_dir = vim.fn.stdpath("data") .. "/site/parser"
        local parser_so = install_parser_dir .. "/ipynb.so"
        -- Resolve tree-sitter-cli's mason install path directly rather than
        -- relying on PATH, since mason.nvim may not have prepended its bin
        -- dir yet at this point (ipynb.nvim loads eagerly via lazy = false,
        -- ahead of lazy-loaded plugins).
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

  --- -------------------------------------------------------------------------
  --- image.nvim -- inline image rendering
  --- -------------------------------------------------------------------------
  --- The old config gave this NO lazy trigger at all -- it loaded (and paid
  --- its ImageMagick/Kitty-protocol setup cost) at startup on every buffer,
  --- notebook or not. `ft` covers both use cases here (markdown for
  --- image.nvim's own markdown integration and Obsidian attachments; ipynb
  --- for notebook cell outputs).
  ---
  --- `cond = not platform.is_win`: image.nvim needs ImageMagick plus the
  --- Kitty graphics protocol, and Windows Terminal does not implement that
  --- protocol. Markdown and notebooks still work fully on Windows -- images
  --- just don't render inline. This is a deliberate, documented gap (see
  --- also core/platform.lua's "KNOWN GAPS ON WINDOWS" note), not a bug to
  --- eventually fix.
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

  --- -------------------------------------------------------------------------
  --- diagram.nvim -- mermaid/plantuml/d2 diagrams rendered as images
  --- -------------------------------------------------------------------------
  --- Needs image.nvim to actually draw the rendered diagram, hence the
  --- dependency; same Windows gap and same reasoning as image.nvim above.
  {
    "3rd/diagram.nvim",
    ft = { "markdown", "ipynb" },
    cond = not platform.is_win,
    dependencies = { "3rd/image.nvim" },
    opts = {
      renderer_options = {
        mermaid = {
          background = nil, --  nil = transparent
          theme = "dark",
        },
      },
    },
  },
}

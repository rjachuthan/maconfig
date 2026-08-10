--- ===========================================================================
--- EDITOR
--- ===========================================================================
--- Text-object, motion and editing-ergonomics plugins. Nothing here touches
--- LSP, git or UI chrome -- those live in lsp.lua, git.lua and ui.lua.
---
--- REMOVED, DELIBERATELY:
---   flash.nvim -- the user opted out. Neovim's own `/` search plus `f`/`t`
---   motions plus the snacks picker already cover jump-to-anywhere; a second
---   overlapping jump plugin was judged not worth the mapping collisions.
---   nvim-spectre -- replaced below by grug-far.nvim (see its entry for why).
--- ===========================================================================

--- ---------------------------------------------------------------------------
--- VS Code muscle memory: Ctrl+/ toggles line comment.
--- Neovim 0.10+ ships built-in commenting (`gc`/`gcc`), so no comment plugin
--- is installed -- these two maps just point familiar keys at it. Both
--- `<C-/>` and `<C-_>` are bound because terminals disagree on which sequence
--- Ctrl+/ actually sends (many send the latter). `remap = true` is required
--- because `gcc`/`gc` are themselves mappings (set up by Neovim internally,
--- not raw commands), so the default `noremap` would make these no-ops.
--- ---------------------------------------------------------------------------
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment (line)" })
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment (line)" })
vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment (selection)" })
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment (selection)" })

return {
  ---------------------------------------------------------------------------
  -- nvim-treesitter: parsers, highlighting, indent.
  -- `branch = "main"` is the new (0.11+) API -- the old `master` branch is in
  -- maintenance mode upstream and doesn't target 0.12. The main branch
  -- compiles parsers from source with a C compiler at install/update time
  -- (see core/platform.lua's check_health() and its per-OS compiler notes),
  -- rather than shipping prebuilt binaries -- hence `build = ":TSUpdate"`.
  --
  -- Folding is NOT configured here: opt.foldexpr already points at
  -- `v:lua.vim.treesitter.foldexpr()` in core/options.lua. Setting it again
  -- here would be redundant and risks fighting that value on every reload.
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = "LazyFile",
    opts = {
      -- Explicit list, not "all" -- only languages actually used in this
      -- config (see lua/plugins/lang/*.lua) plus the small utility grammars
      -- treesitter itself leans on (query, regex) or that markdown/todo
      -- comments pull in (luadoc, luap, jsdoc).
      ensure_installed = {
        "bash",
        "c",
        "css",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        --  No "jsonc" parser: it isn't a separate grammar on the main branch,
        --  and asking for it warns on every startup. The `json` parser above
        --  handles .jsonc files; comment support comes from the jsonls LSP.
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "sql",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "ninja",
        "rst",
        "csv",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
      -- main-branch API: install (and update) is explicit, not part of setup().
      require("nvim-treesitter").install(opts.ensure_installed)
    end,
  },

  ---------------------------------------------------------------------------
  -- nvim-treesitter-textobjects: structural motions/textobjects built on the
  -- same grammars above. main branch keeps pace with the new treesitter API.
  -- The plugin no longer wires its own keymaps on this branch, so the move
  -- keymaps are set up by hand in a FileType autocmd -- this also means they
  -- only attach in buffers that actually have a parser, instead of globally.
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "LazyFile",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local move = require("nvim-treesitter-textobjects.move")
      local select = require("nvim-treesitter-textobjects.select")

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("editor_textobjects", { clear = true }),
        callback = function(ev)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
          end

          -- Jump to next/previous start/end of function, class, parameter.
          map("n", "]f", function() move.goto_next_start("@function.outer") end, "Next function start")
          map("n", "[f", function() move.goto_previous_start("@function.outer") end, "Prev function start")
          map("n", "]F", function() move.goto_next_end("@function.outer") end, "Next function end")
          map("n", "[F", function() move.goto_previous_end("@function.outer") end, "Prev function end")

          map("n", "]c", function() move.goto_next_start("@class.outer") end, "Next class start")
          map("n", "[c", function() move.goto_previous_start("@class.outer") end, "Prev class start")
          map("n", "]C", function() move.goto_next_end("@class.outer") end, "Next class end")
          map("n", "[C", function() move.goto_previous_end("@class.outer") end, "Prev class end")

          map("n", "]a", function() move.goto_next_start("@parameter.inner") end, "Next parameter start")
          map("n", "[a", function() move.goto_previous_start("@parameter.inner") end, "Prev parameter start")
          map("n", "]A", function() move.goto_next_end("@parameter.inner") end, "Next parameter end")
          map("n", "[A", function() move.goto_previous_end("@parameter.inner") end, "Prev parameter end")

          -- Textobjects: af/if = function, ac/ic = class.
          map({ "x", "o" }, "af", function() select.select_textobject("@function.outer") end, "Select outer function")
          map({ "x", "o" }, "if", function() select.select_textobject("@function.inner") end, "Select inner function")
          map({ "x", "o" }, "ac", function() select.select_textobject("@class.outer") end, "Select outer class")
          map({ "x", "o" }, "ic", function() select.select_textobject("@class.inner") end, "Select inner class")
        end,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- nvim-surround: add/change/delete surrounding pairs (quotes, brackets,
  -- tags). `version = "*"` pins to the stable v4 API -- migrated from the v3
  -- default mappings in an earlier commit (see the pre-nvim-next config at
  -- neovim/.config/nvim/lua/plugins/surround.lua), preserved here.
  --
  -- v4 default keymaps (all still active via opts = {}):
  --   ys{motion}{char}   add surround                 e.g. ysiw" -> "word"
  --   yss{char}          surround entire line
  --   yS{motion}{char}   add surround on own lines
  --   S{char}  (visual)  surround selection
  --   ds{char}           delete surround                e.g. ds"
  --   cs{old}{new}       change surround                e.g. cs"'
  ---------------------------------------------------------------------------
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- mini.ai: extends a/i textobjects (quotes, brackets, calls, etc.) with
  -- smarter, treesitter-aware matching and adds next/last variants (an/in,
  -- al/il). Deliberately NOT using LazyVim's `ai_buffer` helper (that module
  -- doesn't exist here) -- this is a plain opts table built directly from
  -- mini.ai's own spec objects.
  ---------------------------------------------------------------------------
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
        },
      }
    end,
  },

  ---------------------------------------------------------------------------
  -- mini.pairs: minimal autopairs (auto-close/-delete brackets and quotes).
  -- Loads on InsertEnter -- pairing only matters once you're actually typing.
  ---------------------------------------------------------------------------
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- todo-comments.nvim: highlights and lets you jump between TODO/FIXME/HACK/
  -- etc. comments. `<leader>st`/`<leader>sT` live under the search group
  -- (owned by tools.lua's picker) rather than `<leader>x` -- the diagnostics/
  -- trouble group is owned by plugins/lsp.lua, and the trouble-backed
  -- `<leader>xt` / `<leader>xT` todo-list variants are registered there
  -- alongside trouble itself, not here.
  ---------------------------------------------------------------------------
  {
    "folke/todo-comments.nvim",
    event = "LazyFile",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      {
        "]t",
        function() require("todo-comments").jump_next() end,
        desc = "Next todo comment",
      },
      {
        "[t",
        function() require("todo-comments").jump_prev() end,
        desc = "Previous todo comment",
      },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Search todos" },
      { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Search todo/fix/fixme" },
    },
  },

  ---------------------------------------------------------------------------
  -- grug-far.nvim: project-wide search-and-replace panel. REPLACES
  -- nvim-spectre, which is deleted -- spectre depended on a working `sed`
  -- (or an oxi binary) and had rough edges on Windows; grug-far shells out to
  -- ripgrep for search and does replacement itself, so it needs no Python
  -- and no external replace engine.
  ---------------------------------------------------------------------------
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function() require("grug-far").open() end,
        desc = "Search and replace (project)",
      },
      {
        "<leader>sr",
        function() require("grug-far").with_visual_selection() end,
        mode = "v",
        desc = "Search and replace (selection)",
      },
      {
        "<leader>sw",
        function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end,
        desc = "Search and replace current word",
      },
    },
  },

  ---------------------------------------------------------------------------
  -- multicursors.nvim: the closest thing to VS Code's Ctrl+D in this config.
  -- Kept specifically for that muscle memory -- select a word/pattern and
  -- spawn cursors at every match. hydra.nvim drives the modal submode you
  -- land in after `<leader>m`.
  ---------------------------------------------------------------------------
  {
    "smoka7/multicursors.nvim",
    dependencies = { "nvimtools/hydra.nvim" },
    opts = {},
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    keys = {
      {
        "<leader>m",
        "<cmd>MCstart<cr>",
        mode = { "n", "v" },
        desc = "Start multicursor",
      },
    },
  },

  ---------------------------------------------------------------------------
  -- persistence.nvim: per-directory session save/restore.
  -- Loads on BufReadPre so the session-tracking autocmd is armed before the
  -- first real file loads (it needs to see that buffer to save it later).
  -- `opt.sessionoptions` (core/options.lua) controls exactly what gets saved.
  ---------------------------------------------------------------------------
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      {
        "<leader>qs",
        function() require("persistence").load() end,
        desc = "Restore session",
      },
      {
        "<leader>qS",
        function() require("persistence").select() end,
        desc = "Select session",
      },
      {
        "<leader>ql",
        function() require("persistence").load({ last = true }) end,
        desc = "Restore last session",
      },
      {
        "<leader>qd",
        function() require("persistence").stop() end,
        desc = "Don't save current session",
      },
      {
        "<leader>qq",
        function() vim.cmd("qa") end,
        desc = "Quit all",
      },
    },
  },
}

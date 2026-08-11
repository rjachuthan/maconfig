vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment (line)" })
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment (line)" })
vim.keymap.set("v", "<C-/>", "gc", { remap = true, desc = "Toggle comment (selection)" })
vim.keymap.set("v", "<C-_>", "gc", { remap = true, desc = "Toggle comment (selection)" })

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = "LazyFile",
    opts = {
      ensure_installed = {
        "bash",
        "c",
        "css",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
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
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
      require("nvim-treesitter").install(opts.ensure_installed)

      -- The `main` branch has no highlight/indent modules: parsers are started
      -- per buffer instead. `foldexpr` is already set globally in core/options.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("editor_treesitter", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or not pcall(vim.treesitter.language.add, lang) then
            return
          end
          pcall(vim.treesitter.start, ev.buf, lang)
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = "LazyFile",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      select = {
        lookahead = true,
        selection_modes = {
          ["@function.outer"] = "V",
          ["@class.outer"] = "V",
        },
        include_surrounding_whitespace = false,
      },
      move = { set_jumps = true },
    },
    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)

      local move = require("nvim-treesitter-textobjects.move")
      local select = require("nvim-treesitter-textobjects.select")
      local swap = require("nvim-treesitter-textobjects.swap")
      local repeatable = require("nvim-treesitter-textobjects.repeatable_move")

      -- key = { capture prefix, name }. `a<key>` / `i<key>` select it,
      -- `]<key>` / `[<key>` jump to its start, `]<KEY>` / `[<KEY>` to its end.
      local objects = {
        f = { "function", "function" },
        c = { "class", "class" },
        a = { "parameter", "parameter" },
        l = { "loop", "loop" },
        i = { "conditional", "conditional" },
      }

      -- Select-only: no useful "jump to next assignment/comment" motion.
      local select_only = {
        ["="] = { "assignment", "assignment" },
        ["/"] = { "comment", "comment" },
      }

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("editor_textobjects", { clear = true }),
        callback = function(ev)
          -- Without a parser every mapping below is a no-op that shadows a
          -- built-in motion, so only attach where treesitter is available.
          local ok, parser = pcall(vim.treesitter.get_parser, ev.buf, nil, { error = false })
          if not ok or not parser then
            return
          end

          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
          end

          local function map_select(key, capture, name)
            map({ "x", "o" }, "a" .. key, function()
              select.select_textobject("@" .. capture .. ".outer", "textobjects")
            end, "Outer " .. name)
            map({ "x", "o" }, "i" .. key, function()
              select.select_textobject("@" .. capture .. ".inner", "textobjects")
            end, "Inner " .. name)
          end

          for key, spec in pairs(objects) do
            local capture, name = spec[1], spec[2]
            map_select(key, capture, name)

            -- Moves work in visual and operator-pending too, so `d]f` and
            -- `v]f` behave like the built-in `]m`.
            local modes = { "n", "x", "o" }
            map(modes, "]" .. key, function()
              move.goto_next_start("@" .. capture .. ".outer", "textobjects")
            end, "Next " .. name .. " start")
            map(modes, "[" .. key, function()
              move.goto_previous_start("@" .. capture .. ".outer", "textobjects")
            end, "Prev " .. name .. " start")
            map(modes, "]" .. key:upper(), function()
              move.goto_next_end("@" .. capture .. ".outer", "textobjects")
            end, "Next " .. name .. " end")
            map(modes, "[" .. key:upper(), function()
              move.goto_previous_end("@" .. capture .. ".outer", "textobjects")
            end, "Prev " .. name .. " end")
          end

          for key, spec in pairs(select_only) do
            map_select(key, spec[1], spec[2])
          end

          map({ "x", "o" }, "as", function()
            select.select_textobject("@local.scope", "locals")
          end, "Outer scope")

          map("n", "<leader>cw", function()
            swap.swap_next("@parameter.inner", "textobjects")
          end, "Swap parameter with next")
          map("n", "<leader>cW", function()
            swap.swap_previous("@parameter.inner", "textobjects")
          end, "Swap parameter with previous")
        end,
      })

      -- `;` / `,` repeat the last textobject move, and still repeat f/F/t/T
      -- when that was the last motion.
      vim.keymap.set({ "n", "x", "o" }, ";", repeatable.repeat_last_move_next, { desc = "Repeat move (forward)" })
      vim.keymap.set({ "n", "x", "o" }, ",", repeatable.repeat_last_move_previous, { desc = "Repeat move (backward)" })
      vim.keymap.set({ "n", "x", "o" }, "f", repeatable.builtin_f_expr, { expr = true, desc = "Find char forward" })
      vim.keymap.set({ "n", "x", "o" }, "F", repeatable.builtin_F_expr, { expr = true, desc = "Find char backward" })
      vim.keymap.set({ "n", "x", "o" }, "t", repeatable.builtin_t_expr, { expr = true, desc = "Till char forward" })
      vim.keymap.set({ "n", "x", "o" }, "T", repeatable.builtin_T_expr, { expr = true, desc = "Till char backward" })
    end,
  },

  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        -- `f` and `c` are owned by nvim-treesitter-textobjects above; mini.ai
        -- only adds what that config does not map.
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }),
        },
      }
    end,
  },

  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },

  {
    "folke/todo-comments.nvim",
    event = "LazyFile",
    cmd = { "TodoTrouble", "TodoQuickFix", "TodoLocList" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = true,
      highlight = { comments_only = true },
    },
    keys = {
      {
        "]t",
        function() require("util.todo").jump({ forward = true }) end,
        desc = "Next todo comment",
      },
      {
        "[t",
        function() require("util.todo").jump({ forward = false }) end,
        desc = "Previous todo comment",
      },
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Search todos" },
      {
        "<leader>sT",
        function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end,
        desc = "Search todo/fix/fixme",
      },
      { "<leader>sq", "<cmd>TodoQuickFix<cr>", desc = "Todos to quickfix" },
    },
  },

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

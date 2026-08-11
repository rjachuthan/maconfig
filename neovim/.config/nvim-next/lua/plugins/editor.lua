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
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
      require("nvim-treesitter").install(opts.ensure_installed)
    end,
  },

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

          map({ "x", "o" }, "af", function() select.select_textobject("@function.outer") end, "Select outer function")
          map({ "x", "o" }, "if", function() select.select_textobject("@function.inner") end, "Select inner function")
          map({ "x", "o" }, "ac", function() select.select_textobject("@class.outer") end, "Select outer class")
          map({ "x", "o" }, "ic", function() select.select_textobject("@class.inner") end, "Select inner class")
        end,
      })
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
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ a = "@block.outer", i = "@block.inner" }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
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

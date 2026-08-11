return {
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = function()
      local icons = require("core.icons").git
      return {
        signs = {
          add = { text = icons.added },
          change = { text = icons.modified },
          delete = { text = icons.removed },
          topdelete = { text = icons.removed },
          changedelete = { text = icons.modified },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          map("n", "]h", function()
            if vim.wo.diff then
              vim.cmd.normal({ "]c", bang = true })
            else
              gs.nav_hunk("next")
            end
          end, "Next hunk")
          map("n", "[h", function()
            if vim.wo.diff then
              vim.cmd.normal({ "[c", bang = true })
            else
              gs.nav_hunk("prev")
            end
          end, "Previous hunk")
          map("n", "]H", function() gs.nav_hunk("last") end, "Last hunk")
          map("n", "[H", function() gs.nav_hunk("first") end, "First hunk")

          map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<cr>", "Stage hunk")
          map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<cr>", "Reset hunk")
          map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
          map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo stage hunk")
          map("n", "<leader>ghR", gs.reset_buffer, "Reset buffer")

          map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview hunk (inline)")
          map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line")
          map("n", "<leader>ghB", function() gs.blame() end, "Blame buffer")
          map("n", "<leader>ghd", gs.diffthis, "Diff this")
          map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff this (against ~)")

          map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
        end,
      }
    end,
  },

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Open diffview" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<cr>", desc = "File history (branch)" },
      { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
    },
    opts = {},
  },
}

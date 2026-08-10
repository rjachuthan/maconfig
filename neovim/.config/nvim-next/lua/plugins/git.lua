--- ===========================================================================
--- GIT
--- ===========================================================================
--- Everything git-shaped: gutter signs/hunk actions and full diff review.
---
--- LAZYGIT IS NOT HERE ON PURPOSE. If you came looking for a lazygit plugin
--- spec, there isn't one -- snacks.nvim ships `Snacks.lazygit()`, and
--- plugins/ui.lua already binds `<leader>gg` to it. Nothing extra is needed
--- beyond the `lazygit` binary itself being on PATH:
---   macOS:   brew install lazygit
---   Windows: winget install JesseDuffield.lazygit
--- `require("core.platform").has("lazygit")` is what core/platform.lua's
--- check_health() uses to warn if it's missing.
--- ===========================================================================

return {
  ---------------------------------------------------------------------------
  -- gitsigns.nvim: gutter signs (added/modified/removed), inline blame,
  -- and buffer-local hunk actions. Signs come from core.icons.git so the
  -- glyphs match whatever lualine's diff section shows -- one source of
  -- truth instead of two icon sets drifting apart.
  --
  -- All hunk maps live under <leader>gh (the "hunk" group), buffer-local via
  -- on_attach so they only exist in buffers gitsigns actually attached to.
  ---------------------------------------------------------------------------
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

          -- Navigation: works across hunks even with a count, and falls back
          -- to a plain jump when not currently inside a diff context.
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

          -- Stage / reset.
          map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<cr>", "Stage hunk")
          map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<cr>", "Reset hunk")
          map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
          map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo stage hunk")
          map("n", "<leader>ghR", gs.reset_buffer, "Reset buffer")

          -- Inspect.
          map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview hunk (inline)")
          map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line")
          map("n", "<leader>ghB", function() gs.blame() end, "Blame buffer")
          map("n", "<leader>ghd", gs.diffthis, "Diff this")
          map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff this (against ~)")

          -- Textobject: `ih` selects the current hunk, e.g. `dih` deletes it.
          map({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
        end,
      }
    end,
  },

  ---------------------------------------------------------------------------
  -- diffview.nvim: full-tree diff review and file/branch history -- the
  -- thing gitsigns' hunk-level view doesn't cover. New addition, requested
  -- separately from the hunk-signs workflow above.
  --
  -- Keys use <leader>g but avoid the `h` slot (that's the hunk group above):
  --   gd  open diffview against HEAD (or a ref you pass via :DiffviewOpen)
  --   gf  file history for the current file
  --   gF  file history for the whole repo/branch
  --   gc  close diffview
  --
  -- In-view keys (set by diffview itself, listed here so they're findable):
  --   <tab> / <s-tab>   cycle changed files
  --   gf                open the file under the cursor
  --   <leader>e         focus/toggle the file panel
  ---------------------------------------------------------------------------
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

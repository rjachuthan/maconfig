-- The default git_branches picker packs branch name, commit id, date and
-- author onto one line in a narrow right-hand preview split, which cramps the
-- branch names. Drop the preview entirely so the full width goes to the
-- branch list.
local function git_branches()
  Snacks.picker.git_branches({
    all = true,
    layout = {
      layout = {
        box = "vertical",
        border = true,
        title = "{title} {live} {flags}",
        title_pos = "center",
        width = 0.7,
        min_width = 100,
        height = 0.5,
        min_height = 15,
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
    },
  })
end

--- Re-link git-picker highlight groups on every colorscheme change so commit
--- id and author stay colour-coded instead of following luna's default dim
--- grey for `SnacksPickerGitCommit`.
local function git_picker_highlights()
  local links = {
    SnacksPickerGitCommit = "DiagnosticHint",
    SnacksPickerGitAuthor = "DiagnosticInfo",
    SnacksPickerGitDate = "Comment",
    SnacksPickerGitBranchCurrent = "String",
    -- Conventional-commit prefix in the preview's log ("type(scope): message").
    SnacksPickerGitType = "Type",
    SnacksPickerGitScope = "DiagnosticWarn",
  }
  local function apply()
    for group, link in pairs(links) do
      vim.api.nvim_set_hl(0, group, { link = link })
    end
  end
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("git_picker_highlights", { clear = true }),
    callback = apply,
  })
  apply()
end

-- Called at require-time (not via the plugin's `init`) because ui.lua already
-- sets `init` on this same "folke/snacks.nvim" spec, and lazy.nvim's spec
-- merge keeps only the last-registered `init` function rather than composing
-- them.
git_picker_highlights()

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit (cwd)" },
      { "<leader>gG", function() Snacks.lazygit({ cwd = require("util.root").get() }) end, desc = "Lazygit (root)" },
      { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit log" },
      { "<leader>gL", function() Snacks.lazygit.log_file() end, desc = "Lazygit log (current file)" },
      { "<leader>gb", git_branches, desc = "Git branches" },
    },
  },

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

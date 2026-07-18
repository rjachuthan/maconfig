return {
  -- Which-key: Register AI/Claude group
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "ai/claude", icon = "󱙺" },
      },
    },
  },

  -- Claude Code integration
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cmd = {
      "ClaudeCode",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeStatus",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeAdd",
      "ClaudeCodeFocus",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeSelectModel",
    },
    config = function()
      require("claudecode").setup({
        -- Terminal configuration

        -- Server configuration
        auto_start = true,
        port_range = { min = 10000, max = 65535 },
        log_level = "info",

        -- Terminal command
        terminal_cmd = "/Users/rituraj/.local/bin/claude",

        -- Behavior settings
        focus_after_send = true,
        track_selection = true,

        -- Working directory configuration (use git repo root)
        git_repo_cwd = true,

        -- Diff settings
        diff_opts = {
          auto_close_on_accept = true,
          layout = "vertical",
          open_in_new_tab = false,
          hide_terminal_in_new_tab = false,
          keep_terminal_focus = false,
          on_new_file_reject = "close_window",
        },
      })
    end,

    -- Keybindings with which-key integration
    keys = {
      -- Normal mode keybindings
      { "<leader>ac", ":ClaudeCode<CR>", desc = "Toggle terminal", mode = "n" },
      { "<leader>af", ":ClaudeCodeFocus<CR>", desc = "Focus terminal", mode = "n" },
      { "<leader>ar", ":ClaudeCode --resume<CR>", desc = "Resume session", mode = "n" },
      { "<leader>ab", ":ClaudeCodeAdd %<CR>", desc = "Add buffer", mode = "n" },
      { "<leader>am", ":ClaudeCodeSelectModel<CR>", desc = "Select model", mode = "n" },
      { "<leader>aa", ":ClaudeCodeDiffAccept<CR>", desc = "Accept diff", mode = "n" },
      { "<leader>ad", ":ClaudeCodeDiffDeny<CR>", desc = "Deny diff", mode = "n" },

      -- Visual mode keybindings
      { "<leader>ac", ":ClaudeCodeSend<CR>", desc = "Send selection", mode = "v" },
      { "<leader>as", ":ClaudeCodeSend<CR>", desc = "Send selection", mode = "v" },
    },
  },
}

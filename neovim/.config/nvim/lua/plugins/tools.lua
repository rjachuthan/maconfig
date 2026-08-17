local platform = require("core.platform")

local terminals = {}

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      { "<c-\\>", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Toggle terminal (bottom)", mode = { "n", "t" } },
      { "<c-`>", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Toggle terminal (VS Code)", mode = { "n", "t" } },

      { "<leader>Tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal: float" },
      { "<leader>Th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal: horizontal" },
      { "<leader>Tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal: vertical" },
      { "<leader>Tt", "<cmd>ToggleTerm<cr>", desc = "Terminal: toggle" },

      { "<leader>Tp", function() terminals.python:toggle() end, desc = "Terminal: Python REPL" },
      { "<leader>Tn", function() terminals.node:toggle() end, desc = "Terminal: Node REPL" },
      {
        "<leader>TH",
        function()
          if not terminals.htop then
            return vim.notify("htop is not installed", vim.log.levels.WARN, { title = "toggleterm" })
          end
          terminals.htop:toggle()
        end,
        desc = "Terminal: htop",
      },
    },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      persist_size = true,
      persist_mode = true,
      direction = "horizontal",
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      float_opts = {
        border = "rounded",
        width = function() return math.floor(vim.o.columns * 0.9) end,
        height = function() return math.floor(vim.o.lines * 0.9) end,
        winblend = 3,
        zindex = 50,
      },
      winbar = { enabled = false },
      highlights = {
        Normal = { link = "Normal" },
        NormalFloat = { link = "NormalFloat" },
        FloatBorder = { link = "FloatBorder" },
      },
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)

      local Terminal = require("toggleterm.terminal").Terminal

      terminals.python = Terminal:new({
        cmd = platform.python(),
        direction = "vertical",
        close_on_exit = false,
      })

      terminals.node = Terminal:new({
        cmd = "node",
        direction = "vertical",
        close_on_exit = false,
      })

      if platform.has("htop") then
        terminals.htop = Terminal:new({
          cmd = "htop",
          direction = "float",
          close_on_exit = true,
        })
      end
    end,
  },

  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    cond = function() return platform.exe("claude") ~= nil end,
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
    keys = {
      { "<leader>ac", ":ClaudeCode<CR>", desc = "Toggle terminal" },
      { "<leader>ac", ":ClaudeCodeSend<CR>", desc = "Send selection", mode = "v" },
      { "<leader>af", ":ClaudeCodeFocus<CR>", desc = "Focus terminal" },
      { "<leader>ar", ":ClaudeCode --resume<CR>", desc = "Resume session" },
      { "<leader>ab", ":ClaudeCodeAdd %<CR>", desc = "Add buffer" },
      { "<leader>am", ":ClaudeCodeSelectModel<CR>", desc = "Select model" },
      { "<leader>aa", ":ClaudeCodeDiffAccept<CR>", desc = "Accept diff" },
      { "<leader>ad", ":ClaudeCodeDiffDeny<CR>", desc = "Deny diff" },
      { "<leader>as", ":ClaudeCodeSend<CR>", desc = "Send selection", mode = "v" },
    },
    config = function()
      require("claudecode").setup({
        auto_start = true,
        port_range = { min = 10000, max = 65535 },
        log_level = "info",
        terminal_cmd = platform.exe("claude") .. " --dangerously-skip-permissions",
        focus_after_send = true,
        track_selection = true,
        git_repo_cwd = true,
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
  },

  {
    "christoomey/vim-tmux-navigator",
    cond = not platform.is_win and vim.env.TMUX ~= nil,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left window/pane" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower window/pane" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper window/pane" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right window/pane" },
    },
  },
}

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

  --- -------------------------------------------------------------------------
  --- GitHub Copilot, via sidekick.nvim
  --- -------------------------------------------------------------------------
  --- Two halves, and only the first is unique:
  ---
  ---   1. Next Edit Suggestions (NES) -- Copilot LSP proposing multi-line
  ---      refactors anywhere in the file, not just ghost text at the cursor.
  ---      Nothing else in this config does this.
  ---   2. An AI CLI terminal, which overlaps claudecode.nvim almost exactly.
  ---
  --- Both are kept deliberately: (2) is here so the overlap can be judged
  --- side by side. When that's settled, either drop claudecode.nvim and move
  --- its <leader>a* keys onto sidekick, or strip the `cli` keys below and
  --- keep sidekick for NES alone.
  ---
  --- Everything lives under <leader>ag so it cannot collide with the
  --- claudecode bindings above -- note that sidekick's own README suggests
  --- <leader>aa/ac/ad/af/as, all five of which are already taken here.
  ---
  --- First run: `:LspCopilotSignIn` (the command is created on attach).
  --- -------------------------------------------------------------------------
  {
    "folke/sidekick.nvim",
    event = "LazyFile",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      nes = { enabled = true },
      cli = {
        watch = true, -- reload buffers the CLI edits under us
        mux = {
          -- Sessions survive detaching from the editor when tmux is there.
          backend = "tmux",
          enabled = vim.env.TMUX ~= nil,
        },
      },
    },
    keys = {
      -- <Tab> applies or jumps to the next suggestion. The fallback returns
      -- a literal <Tab> (no remap), so with no suggestion pending this is
      -- still <C-i> -- jump forward in the jumplist.
      {
        "<tab>",
        function()
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>"
          end
        end,
        expr = true,
        desc = "Next edit suggestion (or jumplist forward)",
      },

      -- NES
      {
        "<leader>agn",
        function()
          require("sidekick").nes_jump_or_apply()
        end,
        desc = "Next edit suggestion",
      },
      {
        "<leader>agu",
        function()
          require("sidekick.nes").update()
        end,
        desc = "Request suggestion now",
      },
      {
        "<leader>agx",
        function()
          require("sidekick.nes").clear()
        end,
        desc = "Clear suggestion",
      },

      -- CLI (the half that overlaps claudecode.nvim)
      {
        "<leader>agg",
        function()
          require("sidekick.cli").toggle({ name = "copilot", focus = true })
        end,
        desc = "Toggle Copilot CLI",
      },
      -- Claude through sidekick, deliberately one keystroke from claudecode's
      -- <leader>ac so the two can be compared directly. sidekick's claude
      -- tool is not a bare terminal: it supports --resume/--continue and
      -- rewrites file references into Claude's @file#L1-2 syntax, which is
      -- what makes the {this}/{file}/{selection} sends below work.
      {
        "<leader>agc",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Toggle Claude (via sidekick)",
      },
      {
        "<leader>agS",
        function()
          require("sidekick.cli").select()
        end,
        desc = "Select CLI",
      },
      {
        "<leader>agd",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach CLI session",
      },
      {
        "<leader>agp",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Select prompt",
      },
      {
        "<leader>agt",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "n", "x" },
        desc = "Send this",
      },
      {
        "<leader>agf",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send file",
      },
      {
        "<leader>agv",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send selection",
      },
    },
  },

  --- The Copilot language server is what actually produces NES. It is not a
  --- diagnostics/completion server, so it wants no filetype restriction --
  --- sidekick asks it for suggestions wherever you are.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        copilot = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "copilot-language-server" })
      return opts
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

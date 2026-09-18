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

  --- -------------------------------------------------------------------------
  --- GitHub Copilot & Claude, via sidekick.nvim
  --- -------------------------------------------------------------------------
  --- Two halves:
  ---
  ---   1. Next Edit Suggestions (NES) -- Copilot LSP proposing multi-line
  ---      refactors anywhere in the file, not just ghost text at the cursor.
  ---   2. An AI CLI terminal (Copilot or Claude) -- supports --resume/
  ---      --continue and rewrites file references into each CLI's own
  ---      syntax, which is what makes the {this}/{file}/{selection} sends
  ---      below work.
  ---
  --- All bindings live under <leader>a, two keystrokes total.
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
        "<leader>an",
        function()
          require("sidekick").nes_jump_or_apply()
        end,
        desc = "Next edit suggestion",
      },
      {
        "<leader>au",
        function()
          require("sidekick.nes").update()
        end,
        desc = "Request suggestion now",
      },
      {
        "<leader>ax",
        function()
          require("sidekick.nes").clear()
        end,
        desc = "Clear suggestion",
      },

      -- CLI
      {
        "<leader>ao",
        function()
          require("sidekick.cli").toggle({ name = "copilot", focus = true })
        end,
        desc = "Toggle Copilot CLI",
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Toggle Claude CLI",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
        end,
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach CLI session",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Select prompt",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "n", "x" },
        desc = "Send this",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send file",
      },
      {
        "<leader>av",
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
    -- The plugin's own terminal-mode mappings use a Vim8 `<C-w>` terminal-normal
    -- trick that Neovim doesn't support, so the raw command text leaks into the
    -- terminal job (e.g. sent straight to a Claude terminal) instead of
    -- switching panes. Disable its mappings and drive it entirely through
    -- lazy.nvim's `<cmd>` keys below, which work correctly from any mode.
    init = function() vim.g.tmux_navigator_no_mappings = 1 end,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", mode = { "n", "t" }, desc = "Go to left window/pane" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", mode = { "n", "t" }, desc = "Go to lower window/pane" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", mode = { "n", "t" }, desc = "Go to upper window/pane" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", mode = { "n", "t" }, desc = "Go to right window/pane" },
    },
  },
}

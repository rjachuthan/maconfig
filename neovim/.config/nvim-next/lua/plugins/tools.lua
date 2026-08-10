--- ===========================================================================
--- TOOLS
--- ===========================================================================
--- Terminal, AI assistant, and tmux/split navigation glue -- the plugins that
--- shell out to something outside Neovim rather than editing a buffer.
---
--- LEADER OWNERSHIP: <leader>T is TERMINAL here. <leader>t is TEST
--- (plugins/test.lua) -- the old config had both toggleterm AND neotest
--- fighting over <leader>t (13 maps vs 10), a genuine daily-annoyance
--- collision. That's why every toggleterm map below is under the capital
--- `T`, not lowercase `t`. Don't move it back.
---
--- REMOVED, DELIBERATELY: zen-mode.nvim. The user opted out of it in this
--- refactor. Removing it also incidentally kills a latent bug: its
--- on_open/on_close hooks called `vim.diagnostic.disable(bufnr)` /
--- `vim.diagnostic.enable(bufnr)`, and `vim.diagnostic.disable` taking a
--- bufnr argument was deprecated/changed shape in Neovim 0.11+, so the old
--- plugin's zen-mode toggle was already quietly broken before this rewrite.
--- ===========================================================================

local platform = require("core.platform")

--- Holds the toggleterm `Terminal:new(...)` singletons (python/node/htop)
--- once `config` below has run. Declared as a module-level upvalue rather
--- than globals (the old config used `_PYTHON_TOGGLE()` etc. on `_G`) so the
--- `keys` closures below can reach them without polluting the global
--- namespace. The keys still work for lazy-loading: pressing one loads the
--- plugin (running `config`, which populates this table) before the closure
--- body executes.
local terminals = {}

return {
  --- -------------------------------------------------------------------------
  --- toggleterm.nvim -- floating/split terminals, plus a few REPL singletons
  --- -------------------------------------------------------------------------
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      --- `<C-\>` is toggleterm's own convention; `<C-`>` (backtick) is added
      --- purely for VS Code muscle memory, where backtick is the integrated
      --- terminal toggle. Both work in normal AND terminal mode so you can
      --- close the float from inside it the same way you opened it.
      { "<c-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal (float)", mode = { "n", "t" } },
      { "<c-`>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal (VS Code)", mode = { "n", "t" } },

      { "<leader>Tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal: float" },
      { "<leader>Th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal: horizontal" },
      { "<leader>Tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal: vertical" },
      { "<leader>Tt", "<cmd>ToggleTerm<cr>", desc = "Terminal: toggle" },

      --- Singletons carried over verbatim (in spirit) from the old config at
      --- neovim/.config/nvim/lua/plugins/toggleterm.lua:70-130. The lazygit
      --- singleton from that file is DELIBERATELY DROPPED: snacks.nvim
      --- already provides `Snacks.lazygit()`, bound to <leader>gg in
      --- plugins/ui.lua, so keeping a second lazygit launcher here would just
      --- be two ways to do the same thing. Do not re-add a `<leader>Tg`.
      { "<leader>Tp", function() terminals.python:toggle() end, desc = "Terminal: Python REPL" },
      { "<leader>Tn", function() terminals.node:toggle() end, desc = "Terminal: Node REPL" },
      {
        "<leader>TH",
        function() terminals.htop:toggle() end,
        desc = "Terminal: htop",
        cond = platform.has("htop"),
      },

      --- Terminal-mode window navigation (<C-h/j/k/l>) and <esc><esc> to drop
      --- back to normal mode are ALREADY set globally in core/keymaps.lua --
      --- deliberately NOT redefined here. Two definitions of the same map in
      --- two files is exactly the kind of drift this refactor is trying to
      --- eliminate.
    },
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      terminal_mappings = true,
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "float",
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

      --- Terminal singletons, carried over from the old config
      --- (neovim/.config/nvim/lua/plugins/toggleterm.lua:70-130). Populated
      --- into the module-level `terminals` upvalue so the `keys` closures
      --- above can reach them. Python uses `platform.python()` instead of a
      --- hardcoded "python3" so it resolves an active venv/conda env first,
      --- same as lang/python.lua does for the LSP.
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

      --- Only constructed when htop is actually on PATH -- the <leader>TH
      --- key itself is also `cond`-gated above, so this mainly guards
      --- against something else in this file calling terminals.htop directly.
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
  --- claudecode.nvim -- AI assistant, terminal-backed
  --- -------------------------------------------------------------------------
  --- The which-key group for <leader>a is NOT registered here. All group
  --- definitions live in lua/keymap-tree.lua, deliberately -- that file is the
  --- single source of truth for the shape of the leader map, and scattering
  --- group definitions across plugin specs is how the old config ended up with
  --- <leader>t claimed by two plugins at once. Bindings belong in `keys` (they
  --- have to, for lazy loading); groups belong in keymap-tree.lua.
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    --- CRITICAL FIX: the old config
    --- (neovim/.config/nvim/lua/plugins/claudecode.lua:42-44) hardcoded BOTH
    --- "/Users/rituraj/.local/bin/claude" (macOS) AND a Windows path under
    --- "C:/Users/achutrit/..." directly into the spec. That breaks the moment
    --- either machine's claude install moves, and baked a second person's
    --- Windows username into a dotfiles repo. `platform.exe("claude")`
    --- resolves it at runtime on whichever machine this actually runs on
    --- (see core/platform.lua's M.exe), and `cond` below skips the whole
    --- plugin -- no server start attempt, no keymaps registered -- when the
    --- binary isn't found, rather than erroring on every startup.
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
        --- Resolved once at setup time via core/platform.lua rather than the
        --- two hardcoded absolute paths the old config carried. `cond` above
        --- already guarantees platform.exe("claude") is non-nil here.
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
  --- vim-tmux-navigator -- seamless <C-h/j/k/l> across tmux panes AND nvim
  --- splits, so the same keys work whether the next pane over is a Neovim
  --- split or a plain shell in another tmux pane.
  --- -------------------------------------------------------------------------
  --- The old config had this as `lazy = false` with a redundant cmd/keys
  --- combo -- fixed here: genuinely lazy via `cmd`/`keys`, plus a `cond` that
  --- skips it entirely when there's no tmux to navigate (no tmux on native
  --- Windows at all, and even on Unix there's nothing to do if this Neovim
  --- instance isn't actually running inside a tmux session). When skipped,
  --- the plain <C-h/j/k/l> window maps in core/keymaps.lua still cover
  --- split-to-split navigation on their own -- nothing breaks, it just stops
  --- trying to also hop across tmux panes.
  --- -------------------------------------------------------------------------
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

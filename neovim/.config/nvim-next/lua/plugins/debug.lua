--- ===========================================================================
--- DEBUG (DAP)
--- ===========================================================================
--- nvim-dap and friends. Everything here is language-agnostic: adapters (the
--- bit that actually knows how to talk to a debugpy/delve/lldb-vscode) are
--- installed via mason-nvim-dap below, but PER-LANGUAGE debug *configurations*
--- (e.g. "launch this file with these args") belong in lua/plugins/lang/*.lua
--- -- python.lua in particular, owned by a different agent on this refactor.
--- Do NOT add dap-python here.
---
--- Leader ownership: <leader>d is DEBUG here. <leader>t is TEST (test.lua),
--- <leader>T is TERMINAL (tools.lua). See the collision note in test.lua for
--- why that split exists -- don't reintroduce it by reusing `d` for anything
--- else.
--- ===========================================================================

local icons = require("core.icons")

return {
  --- -------------------------------------------------------------------------
  --- nvim-dap -- the debug adapter protocol client itself
  --- -------------------------------------------------------------------------
  --- Lazy via `keys` only: nothing here needs to run until you actually press
  --- a <leader>d map or a VS Code function key.
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
      {
        "<leader>dB",
        function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
        desc = "Conditional breakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue / start" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to cursor" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step into" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "Step over" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step out" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run last" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down stack frame" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up stack frame" },
      { "<leader>dP", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dg", function() require("dap").goto_() end, desc = "Go to line (no execute)" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
      {
        "<leader>da",
        function() require("dap").run_last({ args = vim.split(vim.fn.input("Args: "), " ") }) end,
        desc = "Run with args",
      },

      --- VS Code function-key muscle memory. The user migrated from VS Code,
      --- where these are the default debug bindings -- duplicating them here
      --- means the <leader>d maps above are the "discoverable" path and these
      --- are the "fingers already know it" path, same pattern as the <C-p>
      --- picker binding in ui.lua.
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Continue" },
      { "<S-F5>", function() require("dap").terminate() end, desc = "Debug: Terminate" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step into" },
      { "<S-F11>", function() require("dap").step_out() end, desc = "Debug: Step out" },
    },
    config = function()
      local dap = require("dap")

      --- Sign definitions, sourced from core/icons.lua so the debugger reads
      --- the same glyph set as everything else. `Stopped` is a 3-tuple
      --- ({ text, texthl, linehl }) per icons.lua's own comment; every other
      --- entry is a plain string and gets DiagnosticInfo as its default
      --- highlight.
      for name, icon in pairs(icons.dap) do
        if type(icon) == "table" then
          local text, texthl, linehl = icon[1], icon[2], icon[3]
          vim.fn.sign_define("Dap" .. name, { text = text, texthl = texthl, linehl = linehl })
        else
          vim.fn.sign_define("Dap" .. name, { text = icon, texthl = "DiagnosticInfo" })
        end
      end

      --- The line a stopped breakpoint sits on gets a subtle highlight rather
      --- than inventing a new colour -- Visual is already the "something is
      --- selected/active here" signal in this colourscheme.
      vim.api.nvim_set_hl(0, "DapStoppedLine", { link = "Visual" })

      --- mason-nvim-dap is set up HERE, inside nvim-dap's own config, rather
      --- than as its own lazy spec. It needs nvim-dap loaded first to
      --- register adapters against, and doing it in-line guarantees that
      --- order instead of hoping lazy.nvim's dependency graph gets it right.
      require("mason-nvim-dap").setup({
        automatic_installation = true,
        --- IMPORTANT: the `python` handler MUST be a no-op. mason-nvim-dap's
        --- default python handler configures a generic debugpy adapter --
        --- but lang/python.lua configures its own (venv-aware) debugpy setup
        --- via dap-python, run AFTER this plugin's config on the same
        --- `dap.adapters.python` key. If this handler is left at its default,
        --- it wins the race on some startups and silently clobbers the
        --- python-specific config with a generic one. This was a real
        --- footgun in the old setup -- don't remove the empty handler.
        handlers = {
          python = function() end,
        },
      })
    end,
  },

  --- -------------------------------------------------------------------------
  --- nvim-dap-ui -- the variables/scopes/stacks/breakpoints/repl panel layout
  --- -------------------------------------------------------------------------
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
    keys = {
      { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
      { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "x" } },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()

      --- Auto-open the UI the moment a session actually starts (not just on
      --- `dap.continue()`, which can also just be resuming), and auto-close
      --- it once the session is well and truly gone -- both `terminated` and
      --- `exited` fire depending on how the adapter shuts down, so both are
      --- listened for.
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    end,
  },

  --- -------------------------------------------------------------------------
  --- nvim-dap-virtual-text -- inline "x = 5" style annotations while stopped
  --- -------------------------------------------------------------------------
  --- No `keys`/`cmd`/`ft` of its own -- it's purely a passive companion to
  --- nvim-dap, so it loads whenever nvim-dap does.
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    event = "VeryLazy",
    opts = {},
  },

  --- -------------------------------------------------------------------------
  --- mason-nvim-dap -- bridges mason-installed adapters into nvim-dap
  --- -------------------------------------------------------------------------
  --- Deliberately `lazy = true` with no `event`/`cmd`/`keys` of its own: it is
  --- never `require()`d directly by a keymap, only pulled in and `.setup()`
  --- called from inside nvim-dap's `config` above, so lazy.nvim just needs to
  --- have it installed and on the runtimepath before that point.
  {
    "jay-babu/mason-nvim-dap.nvim",
    lazy = true,
    dependencies = { "williamboman/mason.nvim", "mfussenegger/nvim-dap" },
  },
}

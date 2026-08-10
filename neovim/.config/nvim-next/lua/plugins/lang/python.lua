--- ===========================================================================
--- PYTHON
--- ===========================================================================
--- The primary language this config is tuned for. Everything else in
--- plugins/lang/*.lua is "also supported" -- this one gets the most care.
---
--- LSP: basedpyright (vim.g.python_lsp, see core/options.lua) owns hover,
--- go-to-definition, type checking. ruff (vim.g.python_ruff) owns diagnostics,
--- formatting, import sorting, and is deliberately stripped of its own hover
--- so the two servers don't produce two competing hover popups.
---
--- ---------------------------------------------------------------------------
--- VENV CREATION (preserved from the deleted PYTHON_SETUP.md)
--- ---------------------------------------------------------------------------
--- venv (stdlib):
---   python3 -m venv .venv
---   source .venv/bin/activate            # Windows: .venv\Scripts\activate
---   pip install -r requirements.txt
---
--- poetry:
---   poetry init
---   poetry install                       # venv lives under poetry's cache
---                                         # dir, not the project -- that's
---                                         # why venv-selector below has a
---                                         # dedicated poetry search path.
---
--- conda:
---   conda create -n myproject python=3.11
---   conda activate myproject
---
--- Whichever you use, select it in Neovim afterwards with <leader>cv
--- (venv-selector) so the LSP, formatter, linter, debugger and test runner
--- all agree on the same interpreter -- see python_interpreter() below for
--- why "agree on the same interpreter" used to be a real bug.
---
--- ---------------------------------------------------------------------------
--- EXPECTED PROJECT LAYOUT
--- ---------------------------------------------------------------------------
---   my-python-project/
---   |-- .venv/                  virtual environment (venv-selector finds it)
---   |-- src/mypackage/          source, or a flat layout with no src/ at all
---   |-- tests/                  test_*.py or *_test.py (neotest-python finds
---   |                           these; pytest.ini_options.testpaths if not)
---   |-- pyproject.toml          project + tool config (ruff, pytest, mypy)
---   `-- requirements.txt
---
--- ---------------------------------------------------------------------------
--- TROUBLESHOOTING (preserved from the deleted PYTHON_SETUP.md)
--- ---------------------------------------------------------------------------
--- LSP dead:
---   :Mason                 -- confirm basedpyright + ruff show installed
---   :LspInfo                -- confirm a client actually attached to the buf
---   :LspRestart
---
--- Tests undiscovered:
---   - pytest must be installed IN THE ACTIVE VENV, not just on PATH
---   - file naming: test_*.py or *_test.py
---   - :Lazy -- confirm neotest-python loaded (it's ft = "python", so open a
---     .py file first)
---
--- Venv undetected:
---   <leader>cv to select manually, or confirm .venv/ actually contains
---   bin/python (Unix) or Scripts/python.exe (Windows) -- an empty/partial
---   venv directory looks present but has nothing at that path.
---
--- Import errors in the editor but not the terminal:
---   The LSP is very likely resolved to a different interpreter than your
---   shell. <leader>cv, then :LspRestart.
--- ===========================================================================

local platform = require("core.platform")

local python_lsp = vim.g.python_lsp --  "basedpyright" (see core/options.lua)
local python_ruff = vim.g.python_ruff --  "ruff"

--- ---------------------------------------------------------------------------
--- The interpreter, resolved ONCE
--- ---------------------------------------------------------------------------
--- The old config inlined the Unix-only "<venv>/bin/python" form in TWO
--- separate places (dap-python's setup call and neotest-python's `python`
--- option), so venv detection silently broke on Windows for both at once --
--- and the two could theoretically disagree even on Unix if one was ever
--- edited without the other. `core.platform.python()` already does the real
--- resolution (active venv, else <root>/.venv, else PATH) via
--- `platform.python_bin()` internally; this is just the single call site so
--- dap and neotest are structurally incapable of drifting apart again.
---@return string
local function python_interpreter()
  return platform.python(require("util.root").get())
end

--- LspAttach hook: ruff's hover would otherwise fight basedpyright's for the
--- same `K` keypress, and there's no reason to see the weaker of the two.
--- basedpyright owns hover; ruff keeps diagnostics/formatting/import-sorting.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("nvim_lang_python_ruff_hover", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == python_ruff then
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = "Let basedpyright own hover; ruff stays diagnostics/format/imports only",
})

--- Python wants 4-space indents; the config-wide default (core/options.lua)
--- is 2. This is the ftplugin-ish equivalent, scoped to python buffers only.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  group = vim.api.nvim_create_augroup("nvim_lang_python_indent", { clear = true }),
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
  end,
  desc = "PEP 8: 4-space indents",
})

return {
  --- -------------------------------------------------------------------------
  --- LSP servers: basedpyright (types/nav) + ruff (diagnostics/format)
  --- -------------------------------------------------------------------------
  --- Extends nvim-lspconfig's shared opts.servers table -- see the contract
  --- comment at the top of plugins/lsp.lua.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        [python_lsp] = {
          settings = {
            [python_lsp] = {
              analysis = {
                typeCheckingMode = "basic", --  "off" | "basic" | "strict"
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace", --  not just open files
              },
            },
          },
        },
        [python_ruff] = {
          cmd_env = { RUFF_TRACE = "messages" },
          init_options = {
            settings = {
              logLevel = "error", --  ruff's own LSP is chatty at the default level
            },
          },
        },
      },
    },
    --- Organize-imports keymap. There is no server-scoped `keys` field in
    --- this config's opts.servers contract (unlike LazyVim), so it's bound
    --- here directly: a code action targeting ruff's `source.organizeImports`
    --- specifically, applied immediately rather than prompting.
    keys = {
      {
        "<leader>co",
        function()
          vim.lsp.buf.code_action({
            apply = true,
            context = { only = { "source.organizeImports" }, diagnostics = {} },
          })
        end,
        desc = "Organize imports (ruff)",
        ft = "python",
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- Mason: debugpy is the only python tool NOT auto-installed by
  --- mason-lspconfig -- it isn't an LSP server, so it doesn't come along for
  --- free just from being in opts.servers above.
  --- -------------------------------------------------------------------------
  --- Function form + vim.list_extend, not a plain table: multiple lang files
  --- contribute to this same `ensure_installed` list, and a plain-table
  --- `opts` would let the last-loaded file's list silently REPLACE every
  --- earlier one instead of appending to it.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "debugpy" })
      return opts
    end,
  },

  --- -------------------------------------------------------------------------
  --- conform.nvim: ruff for both formatting and import organization
  --- -------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_organize_imports" },
      },
      formatters = {
        ruff_format = {
          command = "ruff",
          args = { "format", "--stdin-filename", "$FILENAME", "-" },
        },
        ruff_organize_imports = {
          command = "ruff",
          args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "-" },
        },
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- nvim-lint: ruff
  --- -------------------------------------------------------------------------
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "ruff" },
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- neotest-python -- contributed to test.lua's shared adapters list
  --- -------------------------------------------------------------------------
  --- Uses the `{ [require_path] = config }` shape from test.lua's ADAPTER
  --- CONTRACT: defers the `require("neotest-python")` call until test.lua's
  --- own `config` runs, and takes `python_interpreter` as a function so the
  --- interpreter is re-resolved per test run rather than frozen at startup
  --- (matters if you switch venvs with <leader>cv mid-session).
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-python" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, {
        ["neotest-python"] = {
          dap = { justMyCode = false },
          runner = "pytest", --  or "unittest"
          python = python_interpreter,
          pytest_discover_instances = true,
        },
      })
      return opts
    end,
  },

  --- -------------------------------------------------------------------------
  --- nvim-dap-python -- debugger
  --- -------------------------------------------------------------------------
  --- debug.lua explicitly refuses to configure dap-python itself (see its
  --- header comment) precisely so this is the one and only place it happens.
  --- `dependencies` pulls in nvim-dap first, which is what guarantees
  --- debug.lua's mason-nvim-dap `handlers.python = function() end` no-op has
  --- already run by the time `dap-python.setup()` below executes -- avoiding
  --- the race documented in debug.lua's comment.
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    keys = {
      {
        "<leader>dPt",
        function()
          require("dap-python").test_method()
        end,
        desc = "Debug method",
        ft = "python",
      },
      {
        "<leader>dPc",
        function()
          require("dap-python").test_class()
        end,
        desc = "Debug class",
        ft = "python",
      },
    },
    config = function()
      require("dap-python").setup(python_interpreter())
    end,
  },

  --- -------------------------------------------------------------------------
  --- venv-selector.nvim -- pick the interpreter interactively
  --- -------------------------------------------------------------------------
  --- `branch = "regexp"`: the actively maintained branch (main was rewritten
  --- around a Python-script backend that's slower to start and not needed
  --- here). Search paths cover every recipe documented at the top of this
  --- file: plain venv/, Anaconda, project-local .venv/, and poetry's cache.
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    ft = "python",
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
        search = {
          venv = { command = "fd -HI -td -a --max-depth=1 '^venv$' ~" },
          anaconda = { command = "fd -HI -td -a --max-depth=1 '^anaconda3$' ~" },
          workspace = { command = "fd -HI -td -a --max-depth=3 '^.venv$'" },
          poetry = { command = "fd -HI -td -a --max-depth=3 '^.venv$' ~/Library/Caches/pypoetry/virtualenvs" },
        },
      },
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" },
    },
  },

  --- -------------------------------------------------------------------------
  --- Treesitter textobjects: function/class navigation
  --- -------------------------------------------------------------------------
  --- Extends nvim-treesitter-textobjects' shared `move` config from
  --- plugins/editor.lua. Works for any language with a `@function.outer` /
  --- `@class.outer` query, but python is where these maps get used daily.
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      textobjects = {
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
      },
    },
  },
}

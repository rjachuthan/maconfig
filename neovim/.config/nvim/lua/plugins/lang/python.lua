local platform = require("core.platform")

local python_lsp = vim.g.python_lsp
local python_ruff = vim.g.python_ruff

---@return string
local function python_interpreter()
  return platform.python(require("util.root").get())
end

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
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        [python_lsp] = {
          settings = {
            [python_lsp] = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                -- "workspace" re-analyses the whole tree on every change --
                -- on a monorepo (or anything with a fat site-packages /
                -- dbt_packages next door) that is seconds of lag and
                -- hundreds of MB resident. ruff already runs project-wide
                -- via nvim-lint, so the type checker only needs what's open.
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },
        [python_ruff] = {
          cmd_env = { RUFF_TRACE = "messages" },
          init_options = {
            settings = {
              logLevel = "error",
            },
          },
        },
      },
    },
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
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "debugpy" })
      return opts
    end,
  },
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
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "ruff" },
      },
    },
  },
  {
    "nvim-neotest/neotest",
    dependencies = { "nvim-neotest/neotest-python" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, {
        ["neotest-python"] = {
          dap = { justMyCode = false },
          runner = "pytest",
          python = python_interpreter,
          pytest_discover_instances = true,
        },
      })
      return opts
    end,
  },
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
  --- ---------------------------------------------------------------------------
  --- Databricks Connect REPL, via iron.nvim
  --- ---------------------------------------------------------------------------
  --- Sends chunks of the current buffer to a persistent ipython REPL instead
  --- of running the whole file, so a Spark session created early in the
  --- buffer survives later sends -- the notebook-cell workflow Databricks
  --- Connect is built around, without a Jupyter kernel.
  ---
  --- The REPL launches ipython under a dedicated `databricks` profile (not
  --- profile_default), so plain `ipython` elsewhere on the machine is
  --- unaffected. That profile's startup script (stowed from
  --- ipython/.ipython/profile_databricks/startup/) builds `spark` via
  --- DatabricksSession.builder.getOrCreate() -- auth comes from
  --- DATABRICKS_HOST/TOKEN/CLUSTER_ID env vars or ~/.databrickscfg, same as
  --- util/db.lua's env-vars-only rule, never from this repo. The interpreter
  --- is whichever venv-selector.nvim has active, so `databricks-connect`
  --- (pinned to the cluster's DBR runtime version) and `ipython` need to be
  --- installed in that project's venv.
  ---
  --- `<leader>rc` sends the cell under the cursor, delimited by `# %%` or
  --- Databricks' own `# COMMAND ----------` markers, so notebooks exported
  --- from Databricks work unchanged.
  {
    "Vigemus/iron.nvim",
    ft = "python",
    config = function()
      local iron = require("iron.core")
      local view = require("iron.view")
      local common = require("iron.fts.common")
      local venv = require("util.venv")

      iron.setup({
        config = {
          scratch_repl = true,
          close_window_on_exit = true,
          repl_definition = {
            python = {
              command = function()
                local ipython = venv.bin("ipython")
                if vim.fn.executable(ipython) == 0 then
                  vim.notify(
                    "No ipython found for the active venv (got '"
                      .. ipython
                      .. "'). Select the project's venv with <leader>cv, or pip install ipython into it.",
                    vim.log.levels.ERROR,
                    { title = "Databricks REPL" }
                  )
                end
                return { ipython, "--profile=databricks", "--no-autoindent" }
              end,
              format = common.bracketed_paste_python,
              block_dividers = { "# %%", "# COMMAND ----------" },
            },
          },
          -- Horizontal, not vertical: wide Spark `.show()` output wraps
          -- illegibly once it exceeds a fixed-width vertical split, so the
          -- REPL gets the full editor width instead.
          repl_open_cmd = view.split.horizontal.botright(20),
        },
        keymaps = {
          send_motion = "<leader>rm",
          visual_send = "<leader>r",
          send_line = "<leader>rl",
          send_until_cursor = "<leader>ru",
          send_file = "<leader>rf",
          send_code_block = "<leader>rc",
          send_code_block_and_move = "<leader>rC",
          interrupt = "<leader>rx",
          exit = "<leader>rq",
          clear = "<leader>rd",
        },
        highlight = { italic = true },
        ignore_blank_lines = true,
      })

      vim.keymap.set("n", "<leader>ro", function()
        iron.focus_on("python")
      end, { desc = "Focus REPL" })
      vim.keymap.set("n", "<leader>rR", function()
        iron.repl_restart()
      end, { desc = "Restart REPL" })
    end,
  },

  {
    "linux-cultist/venv-selector.nvim",
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
}

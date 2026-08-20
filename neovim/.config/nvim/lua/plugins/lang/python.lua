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

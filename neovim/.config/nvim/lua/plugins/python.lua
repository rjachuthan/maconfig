return {
  -- Treesitter: Python syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "python",
          "ninja", -- for CMake/build files
          "rst",   -- for reStructuredText docs
          "toml",  -- for pyproject.toml
        })
      end
    end,
  },

  -- LSP: Pyright + Ruff
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          enabled = vim.g.lazyvim_python_lsp == "pyright",
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic", -- "off", "basic", "strict"
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace", -- "openFilesOnly" or "workspace"
                stubPath = vim.fn.stdpath("data") .. "/lazy/python-type-stubs",
              },
            },
          },
        },
        basedpyright = {
          enabled = vim.g.lazyvim_python_lsp == "basedpyright",
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "workspace",
              },
            },
          },
        },
        ruff = {
          cmd_env = { RUFF_TRACE = "messages" },
          init_options = {
            settings = {
              logLevel = "error",
            },
          },
          keys = {
            {
              "<leader>co",
              function()
                vim.lsp.buf.code_action({
                  apply = true,
                  context = {
                    only = { "source.organizeImports" },
                    diagnostics = {},
                  },
                })
              end,
              desc = "Organize Imports",
            },
          },
        },
      },
    },
  },

  -- Mason: Install Python tools
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "pyright",     -- Python LSP
        "ruff",        -- Fast Python linter & formatter
        "debugpy",     -- Python debugger
        "black",       -- Python formatter (alternative)
        "isort",       -- Import sorter (alternative)
        "mypy",        -- Static type checker
      })
    end,
  },

  -- conform.nvim: Python formatting
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

  -- nvim-lint: Python linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "ruff", "mypy" },
      },
    },
  },

  -- neotest: Python testing
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
    },
    opts = function(_, opts)
      -- Ensure adapters table exists
      opts.adapters = opts.adapters or {}

      -- Add neotest-python adapter
      table.insert(
        opts.adapters,
        require("neotest-python")({
          dap = { justMyCode = false },
          runner = "pytest", -- "pytest" or "unittest"
          python = function()
            -- Use virtual environment python if available
            local venv = vim.env.VIRTUAL_ENV
            if venv then
              return venv .. "/bin/python"
            end
            return vim.fn.exepath("python3") or vim.fn.exepath("python")
          end,
          pytest_discover_instances = true,
        })
      )

      return opts
    end,
  },

  -- nvim-dap: Python debugging
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
      config = function()
        local dap_python = require("dap-python")
        -- Use virtual environment debugpy if available, otherwise use Mason's
        local venv = vim.env.VIRTUAL_ENV
        if venv then
          dap_python.setup(venv .. "/bin/python")
        else
          dap_python.setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")
        end
      end,
    },
    keys = {
      {
        "<leader>dPt",
        function()
          require("dap-python").test_method()
        end,
        desc = "Debug Method",
        ft = "python",
      },
      {
        "<leader>dPc",
        function()
          require("dap-python").test_class()
        end,
        desc = "Debug Class",
        ft = "python",
      },
    },
  },

  -- venv-selector: Virtual environment management
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    cmd = "VenvSelect",
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
        search = {
          -- Search for virtual environments in these locations
          venv = {
            command = "fd -HI -td -a --max-depth=1 '^venv$' ~",
          },
          anaconda = {
            command = "fd -HI -td -a --max-depth=1 '^anaconda3$' ~",
          },
          workspace = {
            command = "fd -HI -td -a --max-depth=3 '^.venv$'",
          },
          poetry = {
            command = "fd -HI -td -a --max-depth=3 '^.venv$' ~/Library/Caches/pypoetry/virtualenvs",
          },
        },
      },
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" },
    },
  },

  -- Additional Python utilities
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      textobjects = {
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
          },
          goto_next_end = {
            ["]F"] = "@function.outer",
            ["]C"] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
          },
          goto_previous_end = {
            ["[F"] = "@function.outer",
            ["[C"] = "@class.outer",
          },
        },
      },
    },
  },
}

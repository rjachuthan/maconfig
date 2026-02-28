return {
  "akinsho/toggleterm.nvim",
  version = "*",
  cmd = { "ToggleTerm", "TermExec" },
  config = function()
    require("toggleterm").setup({
      -- Size configuration
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,

      -- Open mappings
      open_mapping = [[<c-\>]],

      -- Terminal mode mappings
      terminal_mappings = true,

      -- Behavior
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      persist_mode = true,

      -- Layout
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,

      -- Float terminal configuration
      float_opts = {
        border = "rounded",
        width = function()
          return math.floor(vim.o.columns * 0.9)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.9)
        end,
        winblend = 3,
        zindex = 50,
      },

      -- Window options
      winbar = {
        enabled = false,
      },

      -- Highlights
      highlights = {
        Normal = {
          link = "Normal",
        },
        NormalFloat = {
          link = "NormalFloat",
        },
        FloatBorder = {
          link = "FloatBorder",
        },
      },
    })

    -- Terminal wrapper functions for specific use cases
    local Terminal = require("toggleterm.terminal").Terminal

    -- Lazygit integration
    local lazygit = Terminal:new({
      cmd = "lazygit",
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "rounded",
        width = function()
          return math.floor(vim.o.columns * 0.95)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.95)
        end,
      },
      on_open = function(term)
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
      end,
      on_close = function()
        vim.cmd("startinsert!")
      end,
    })

    function _LAZYGIT_TOGGLE()
      lazygit:toggle()
    end

    -- Python REPL
    local python = Terminal:new({
      cmd = "python3",
      direction = "vertical",
      close_on_exit = false,
    })

    function _PYTHON_TOGGLE()
      python:toggle()
    end

    -- Node REPL
    local node = Terminal:new({
      cmd = "node",
      direction = "vertical",
      close_on_exit = false,
    })

    function _NODE_TOGGLE()
      node:toggle()
    end

    -- Htop
    local htop = Terminal:new({
      cmd = "htop",
      direction = "float",
      close_on_exit = true,
    })

    function _HTOP_TOGGLE()
      htop:toggle()
    end
  end,

  keys = {
    -- Toggle terminals with different directions
    { "<c-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal (float)", mode = { "n", "t" } },
    { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal: Float", mode = "n" },
    { "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal: Horizontal", mode = "n" },
    { "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal: Vertical", mode = "n" },
    { "<leader>tt", "<cmd>ToggleTerm direction=tab<cr>", desc = "Terminal: Tab", mode = "n" },

    -- Multiple terminals (numbered)
    { "<leader>t1", "<cmd>1ToggleTerm<cr>", desc = "Terminal: #1", mode = "n" },
    { "<leader>t2", "<cmd>2ToggleTerm<cr>", desc = "Terminal: #2", mode = "n" },
    { "<leader>t3", "<cmd>3ToggleTerm<cr>", desc = "Terminal: #3", mode = "n" },
    { "<leader>t4", "<cmd>4ToggleTerm<cr>", desc = "Terminal: #4", mode = "n" },

    -- Special terminals
    { "<leader>tg", "<cmd>lua _LAZYGIT_TOGGLE()<cr>", desc = "Terminal: Lazygit", mode = "n" },
    { "<leader>tp", "<cmd>lua _PYTHON_TOGGLE()<cr>", desc = "Terminal: Python", mode = "n" },
    { "<leader>tn", "<cmd>lua _NODE_TOGGLE()<cr>", desc = "Terminal: Node", mode = "n" },
    { "<leader>tH", "<cmd>lua _HTOP_TOGGLE()<cr>", desc = "Terminal: Htop", mode = "n" },

    -- Send commands to terminal
    { "<leader>ts", "<cmd>TermExec cmd='", desc = "Terminal: Send command", mode = "n" },

    -- Terminal navigation (in terminal mode)
    { "<C-h>", "<cmd>wincmd h<cr>", desc = "Go to left window", mode = "t" },
    { "<C-j>", "<cmd>wincmd j<cr>", desc = "Go to lower window", mode = "t" },
    { "<C-k>", "<cmd>wincmd k<cr>", desc = "Go to upper window", mode = "t" },
    { "<C-l>", "<cmd>wincmd l<cr>", desc = "Go to right window", mode = "t" },

    -- Exit terminal mode
    { "<esc><esc>", "<C-\\><C-n>", desc = "Exit terminal mode", mode = "t" },
  },
}

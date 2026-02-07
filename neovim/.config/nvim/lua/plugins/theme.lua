return {
  {
    "rose-pine/neovim",
    config = function()
      require("rose-pine").setup({ styles = { transparency = true } })
    end,
  },
  {
    "padulkemid/nvim-256noir",
    lazy = false,
    priority = 1000,
    config = function()
      -- Colorscheme will be set by LazyVim opts below
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "256noir" },
  },
}

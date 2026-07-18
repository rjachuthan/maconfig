-- ============================================================================
-- Transparent background (match terminal background)
-- ============================================================================
--
-- local function apply_transparent_bg()
--   local groups = {
--     "Normal", "NormalNC", "NormalFloat", "FloatBorder",
--     "SignColumn", "FoldColumn", "EndOfBuffer",
--     "StatusLine", "StatusLineNC",
--     "WinBar", "WinBarNC",
--   }
--   for _, group in ipairs(groups) do
--     vim.api.nvim_set_hl(0, group, { bg = "NONE", ctermbg = "NONE" })
--   end
-- end
--
-- vim.api.nvim_create_autocmd("ColorScheme", {
--   group = vim.api.nvim_create_augroup("transparent_bg", { clear = true }),
--   pattern = "*",
--   callback = apply_transparent_bg,
--   desc = "Make background transparent to match terminal",
-- })
--
-- apply_transparent_bg()
-- ============================================================================

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
    "oskarnurm/koda.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("koda").setup()
    end,
  },
  {
    "AlexvZyl/nordic.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("nordic").setup({
        transparent = {
          -- Enable transparent background.
          bg = true,
          -- Enable transparent background for floating windows.
          float = true,
        },
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "koda" },
  },
}

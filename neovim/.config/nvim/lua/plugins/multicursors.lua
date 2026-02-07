return {
  -- Which-key: Register multicursor group
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>m", group = "multicursor", icon = "󰘪" },
      },
    },
  },

  -- Multi-cursor support for Neovim
  {
    "smoka7/multicursors.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvimtools/hydra.nvim",
    },
    opts = {},
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    keys = {
      {
        mode = { "v", "n" },
        "<leader>m",
        "<cmd>MCstart<cr>",
        desc = "Start multicursor",
      },
    },
  },
}

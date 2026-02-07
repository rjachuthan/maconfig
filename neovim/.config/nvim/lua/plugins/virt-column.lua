return {
  -- Display virtual column lines
  {
    "lukas-reineke/virt-column.nvim",
    event = "VeryLazy",
    config = function()
      require("virt-column").setup({
        virtcolumn = "80,120",
      })
    end,
  },
}


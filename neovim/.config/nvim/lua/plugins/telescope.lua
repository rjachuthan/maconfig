-- Telescope fuzzy finder configuration
return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      -- Show hidden files in all pickers
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden", -- Search in hidden files
        "--glob=!.git/", -- But ignore .git directory
      },
    },
    pickers = {
      find_files = {
        hidden = true, -- Show hidden files
        -- Optionally, add patterns to ignore
        find_command = {
          "rg",
          "--files",
          "--hidden",
          "--glob=!.git/",
          "--glob=!node_modules/",
          "--glob=!.DS_Store",
        },
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
    },
  },
}

-- Neo-tree file explorer configuration
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- Show hidden files by default
        hide_dotfiles = false,
        hide_gitignored = false, -- ALWAYS show gitignored files
        hide_hidden = false, -- Only works on Windows for hidden files
        hide_by_name = {
          -- Empty: don't hide any files/folders by name
        },
        hide_by_pattern = {
          -- Empty: don't hide any files/folders by pattern
        },
        always_show = { -- Keep these visible even if other rules would hide them
          ".gitignored",
          ".env",
          "data", -- Explicitly show data folders
        },
        always_show_by_pattern = { -- Always show folders matching these patterns
          "data",
          "data/*",
        },
        never_show = { -- Never show these
          ".DS_Store",
          "thumbs.db",
        },
      },
      follow_current_file = {
        enabled = true, -- Focus on current file
        leave_dirs_open = false,
      },
      -- Ensure we use git status but don't filter based on it
      use_libuv_file_watcher = true,
    },
    window = {
      mappings = {
        -- Toggle gitignored files visibility with 'gi'
        ["gi"] = "toggle_gitignored",
        -- Toggle hidden files with 'H'
        ["H"] = "toggle_hidden",
      },
    },
    -- Override default commands to ensure visibility
    default_component_configs = {
      git_status = {
        symbols = {
          -- Show all git statuses
          added     = "✚",
          modified  = "",
          deleted   = "✖",
          renamed   = "󰁕",
          untracked = "",
          ignored   = "",
          unstaged  = "󰄱",
          staged    = "",
          conflict  = "",
        },
      },
    },
  },
}

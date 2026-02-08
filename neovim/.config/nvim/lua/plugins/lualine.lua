return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    -- Change separators from arrows to rectangles
    opts.options = opts.options or {}
    opts.options.section_separators = { left = "█", right = "█" }
    opts.options.component_separators = { left = "│", right = "│" }

    -- Fix middle section background (change from white to black/dark)
    -- Create a custom theme with dark backgrounds for better visibility
    local custom_theme = {
      normal = {
        a = { bg = "#4e4e4e", fg = "#ffffff", gui = "bold" },
        b = { bg = "#3a3a3a", fg = "#ffffff" },
        c = { bg = "#262626", fg = "#ffffff" }, -- Middle section: dark background, white text
      },
      insert = {
        a = { bg = "#4e4e4e", fg = "#ffffff", gui = "bold" },
        b = { bg = "#3a3a3a", fg = "#ffffff" },
        c = { bg = "#262626", fg = "#ffffff" },
      },
      visual = {
        a = { bg = "#4e4e4e", fg = "#ffffff", gui = "bold" },
        b = { bg = "#3a3a3a", fg = "#ffffff" },
        c = { bg = "#262626", fg = "#ffffff" },
      },
      replace = {
        a = { bg = "#4e4e4e", fg = "#ffffff", gui = "bold" },
        b = { bg = "#3a3a3a", fg = "#ffffff" },
        c = { bg = "#262626", fg = "#ffffff" },
      },
      command = {
        a = { bg = "#4e4e4e", fg = "#ffffff", gui = "bold" },
        b = { bg = "#3a3a3a", fg = "#ffffff" },
        c = { bg = "#262626", fg = "#ffffff" },
      },
      inactive = {
        a = { bg = "#262626", fg = "#767676" },
        b = { bg = "#262626", fg = "#767676" },
        c = { bg = "#262626", fg = "#767676" },
      },
    }

    opts.options.theme = custom_theme

    -- Customize sections - remove unwanted components
    opts.sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" }, -- Removed: 'diff' (git diff stats)
      lualine_c = { "diagnostics" }, -- Removed: 'filename' (file path/name)
      lualine_x = {}, -- Removed: 'filetype', 'encoding', 'fileformat'
      lualine_y = {}, -- Removed: 'progress' (file progress percentage)
      lualine_z = {
        -- Show only line number, not column
        function()
          return "L" .. vim.fn.line(".")
        end,
      },
    }

    return opts
  end,
}

--[[
LUALINE SECTION LAYOUT:
=======================

LEFT SIDE:
  lualine_a: Mode indicator (NORMAL, INSERT, VISUAL, etc.)
  lualine_b: Branch name, git diff stats
  lualine_c: Diagnostics (errors/warnings), file path/name

MIDDLE (RIGHT SIDE):
  lualine_x: File type, encoding, file format
  lualine_y: File progress percentage
  lualine_z: Line:Column position

To customize sections, add to opts:
  opts.sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff' },
    lualine_c = { 'diagnostics', 'filename' },
    lualine_x = { 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' }
  }

Available components:
  'mode', 'branch', 'diff', 'diagnostics', 'filename', 'filetype',
  'encoding', 'fileformat', 'progress', 'location', 'searchcount',
  'selectioncount', 'tabs', 'windows'

You can also add custom components with Lua functions.
--]]
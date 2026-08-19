local icons = require("core.icons")
local platform = require("core.platform")

--- Strip the background from every highlight group whose name matches one of
--- `patterns`, so the terminal (and its blur) shows through. Runs after the
--- colorscheme so plugins that derive their own groups at load time are caught
--- too.
---@param patterns string[]
local function clear_backgrounds(patterns)
  for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
    for _, pattern in ipairs(patterns) do
      if name:match(pattern) and (def.bg ~= nil or def.ctermbg ~= nil) then
        def.bg, def.ctermbg = nil, nil
        vim.api.nvim_set_hl(0, name, def)
        break
      end
    end
  end
end

--- Render plain text as a slimline component: the same padding slimline's own
--- `fg` style components use, highlighted like the primary part of `follow` so
--- custom components pick up the style recipe for free. Empty text renders
--- nothing so slimline drops the component entirely.
---@param text string
---@param follow string? name of a slimline component to borrow the highlight from
---@return string
local function slimline_text(text, follow)
  if text == nil or text == "" then
    return ""
  end
  local hls = require("slimline").highlights.hls
  local hl = hls.base
  local component = follow and hls.components[follow]
  if component and component.primary and component.primary.text then
    hl = component.primary.text
  end
  return string.format("%%#%s# %s ", hl, text)
end

return {
  {
    "wtfox/luna.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("luna").setup({ transparent = true })

      -- luna's own `transparent` covers core and most plugin groups; these are
      -- derived from the colorscheme by plugins, some of which only load on
      -- VeryLazy, so re-run on both events.
      local group = vim.api.nvim_create_augroup("luna_transparent", { clear = true })
      local function untint()
        clear_backgrounds({ "^BufferLine", "^Noice", "^TabLine", "^MsgArea", "^StatusLine" })
      end
      vim.api.nvim_create_autocmd("ColorScheme", { group = group, pattern = "luna", callback = untint })
      vim.api.nvim_create_autocmd("User", { group = group, pattern = "VeryLazy", callback = untint })

      vim.cmd.colorscheme("luna")
    end,
  },

  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    keys = {
      {
        "<leader><space>",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files",
      },
      {
        "<leader>,",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep (project)",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command history",
      },
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "Explorer (toggle)",
      },
      {
        "<leader>.",
        function()
          Snacks.scratch()
        end,
        desc = "Toggle scratch buffer",
      },
      {
        "<leader>S",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select scratch buffer",
      },

      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent files",
      },
      {
        "<leader>fc",
        function()
          Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Find config file",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Find buffer",
      },
      {
        "<leader>fp",
        function()
          Snacks.picker.projects()
        end,
        desc = "Find project",
      },

      {
        "<leader>sg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep (project)",
      },
      {
        "<leader>sb",
        function()
          Snacks.picker.lines()
        end,
        desc = "Buffer lines",
      },
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help pages",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      {
        "<leader>sj",
        function()
          Snacks.picker.jumps()
        end,
        desc = "Jumps",
      },
      {
        "<leader>sr",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume last search",
      },
      {
        "<leader>su",
        function()
          Snacks.picker.undo()
        end,
        desc = "Undo history",
      },
      {
        "<leader>sc",
        function()
          Snacks.picker.commands()
        end,
        desc = "Commands",
      },
      {
        "<leader>sC",
        function()
          Snacks.picker.colorschemes()
        end,
        desc = "Colorschemes",
      },
      {
        "<leader>sH",
        function()
          Snacks.picker.highlights()
        end,
        desc = "Highlight groups",
      },
      {
        "<leader>si",
        function()
          Snacks.picker.icons()
        end,
        desc = "Icons",
      },
      {
        "<leader>sM",
        function()
          Snacks.picker.man()
        end,
        desc = "Man pages",
      },

      {
        "<leader>un",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification history",
      },

      {
        "<C-p>",
        function()
          Snacks.picker.files()
        end,
        desc = "Find files (VS Code)",
      },
      {
        "<C-S-p>",
        function()
          Snacks.picker.commands()
        end,
        desc = "Command palette (VS Code)",
      },
      {
        "<C-S-f>",
        function()
          Snacks.picker.grep()
        end,
        desc = "Find in files (VS Code)",
      },
      {
        "<C-b>",
        function()
          Snacks.explorer()
        end,
        desc = "Toggle sidebar (VS Code)",
      },

      {
        "<leader>uf",
        function()
          Snacks.toggle({
            name = "Autoformat",
            get = function()
              return vim.g.autoformat
            end,
            set = function(state)
              vim.g.autoformat = state
            end,
          }):toggle()
        end,
        desc = "Toggle autoformat",
      },
      {
        "<leader>uF",
        function()
          Snacks.toggle({
            name = "Autoformat (buffer)",
            get = function()
              return vim.b.autoformat
            end,
            set = function(state)
              vim.b.autoformat = state
            end,
          }):toggle()
        end,
        desc = "Toggle autoformat (buffer)",
      },
      {
        "<leader>us",
        function()
          Snacks.toggle.option("spell", { name = "Spelling" }):toggle()
        end,
        desc = "Toggle spelling",
      },
      {
        "<leader>uw",
        function()
          Snacks.toggle.option("wrap", { name = "Wrap" }):toggle()
        end,
        desc = "Toggle wrap",
      },
      {
        "<leader>uL",
        function()
          Snacks.toggle.option("relativenumber", { name = "Relative number" }):toggle()
        end,
        desc = "Toggle relative number",
      },
      {
        "<leader>ud",
        function()
          Snacks.toggle.diagnostics():toggle()
        end,
        desc = "Toggle diagnostics",
      },
      {
        "<leader>ul",
        function()
          Snacks.toggle.option("number", { name = "Number" }):toggle()
        end,
        desc = "Toggle line number",
      },
      {
        "<leader>uc",
        function()
          Snacks.toggle.option("conceallevel", { off = 0, on = 2 }):toggle()
        end,
        desc = "Toggle conceal",
      },
      {
        "<leader>uT",
        function()
          Snacks.toggle.treesitter():toggle()
        end,
        desc = "Toggle treesitter highlight",
      },
      {
        "<leader>ub",
        function()
          Snacks.toggle.option("background", { off = "light", on = "dark" }):toggle()
        end,
        desc = "Toggle background",
      },
      {
        "<leader>ug",
        function()
          Snacks.toggle.indent():toggle()
        end,
        desc = "Toggle indent guides",
      },
      {
        "<leader>uh",
        function()
          Snacks.toggle.inlay_hints():toggle()
        end,
        desc = "Toggle inlay hints",
      },
      {
        "<leader>uD",
        function()
          Snacks.toggle.dim():toggle()
        end,
        desc = "Toggle dim (focus)",
      },
    },
    opts = {
      dashboard = {
        preset = {
          header = {},
        },
        sections = {
          { section = "keys", gap = 0, padding = 1 },
          { icon = "\u{f1da} ", title = "Recent Files", section = "recent_files", indent = 1, padding = 1 },
          { icon = "\u{f07b} ", title = "Projects", section = "projects", indent = 1, padding = 0 },
        },
      },

      image = {
        enabled = not platform.is_win,
        resolve = function(path, src)
          local ok, api = pcall(require, "obsidian.api")
          if ok and api then
            local is_note_ok, is_note = pcall(api.path_is_note, path)
            if is_note_ok and is_note then
              local resolved_ok, resolved = pcall(api.resolve_attachment_path, src)
              if resolved_ok then
                return resolved
              end
            end
          end
          return nil
        end,
        doc = {
          enabled = true,
          inline = true,
          max_height_window_percentage = 50,
        },
      },

      picker = { enabled = true },
      explorer = { enabled = true },

      lazygit = {
        configure = true,
        config = {
          os = { editPreset = "nvim-remote" },
          gui = { nerdFontsVersion = "3" },
        },
        win = { style = "lazygit", border = "rounded" },
      },

      statuscolumn = { enabled = true },

      notifier = { enabled = true },
      indent = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      words = { enabled = true },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      input = { enabled = true },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer-local keymaps",
      },
    },
    config = function(_, opts)
      require("which-key").setup(opts)
      require("keymap-tree").setup()
    end,
  },

  {
    "sschleemilch/slimline.nvim",
    event = "VeryLazy",
    opts = {
      -- "pure" recipe: no backgrounds, bold primaries, semantic highlights.
      style = "fg",
      bold = true,
      components = {
        left = { "mode", "path", "git" },
        center = {},
        right = {
          -- Ahead/behind counts against the upstream branch, on top of
          -- slimline's own `git` component.
          function()
            return slimline_text(require("util.git_sync").status(), "git")
          end,
          -- Active Python virtualenv.
          function()
            local venv = require("util.venv")
            if not venv.enabled() then
              return ""
            end
            return slimline_text("\u{e73c} " .. venv.name(), "filetype_lsp")
          end,
          "diagnostics",
          "filetype_lsp",
          "progress",
        },
      },
      configs = {
        path = {
          hl = { primary = "Label" },
        },
        git = {
          hl = { primary = "Function" },
          icons = {
            branch = icons.git.branch,
            added = icons.git.added,
            modified = icons.git.modified,
            removed = icons.git.removed,
          },
        },
        diagnostics = {
          icons = {
            ERROR = icons.diagnostics.Error,
            WARN = icons.diagnostics.Warn,
            INFO = icons.diagnostics.Info,
            HINT = icons.diagnostics.Hint,
          },
        },
        filetype_lsp = {
          hl = { primary = "String" },
        },
      },
    },
  },

  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin buffer" },
      { "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Delete non-pinned buffers" },
      { "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Delete buffers to the right" },
      { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Delete buffers to the left" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Delete other buffers" },
      { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete buffer" },
    },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        always_show_bufferline = true,
        offsets = {
          {
            filetype = "snacks_layout_box",
            text = "\u{f07c} Explorer",
            highlight = "Directory",
            text_align = "left",
            separator = true,
          },
        },
      },
    },
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    keys = {
      {
        "<c-f>",
        function()
          if not require("noice.lsp").scroll(4) then
            return "<c-f>"
          end
        end,
        silent = true,
        expr = true,
        mode = { "i", "n", "s" },
        desc = "Scroll forward (LSP doc)",
      },
      {
        "<c-b>",
        function()
          if not require("noice.lsp").scroll(-4) then
            return "<c-b>"
          end
        end,
        silent = true,
        expr = true,
        mode = { "i", "n", "s" },
        desc = "Scroll backward (LSP doc)",
      },
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
        signature = { enabled = true },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },

  {
    "nvim-mini/mini.icons",
    lazy = true,
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
    opts = {},
  },

  {
    "lukas-reineke/virt-column.nvim",
    event = "VeryLazy",
    opts = { char = "\u{2502}" },
  },
}

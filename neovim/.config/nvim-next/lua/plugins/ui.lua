--- ===========================================================================
--- UI
--- ===========================================================================
--- The visual layer: colourscheme, statusline, tabline, cmdline, and the
--- snacks.nvim suite (dashboard/picker/explorer/notifier/...). This is the
--- file with the config's heaviest keymap surface -- <leader>f, <leader>s,
--- <leader>u and the VS Code compatibility keys all live here because they
--- belong to plugins defined here. See lua/keymap-tree.lua for the group
--- headers and the ownership table.
--- ===========================================================================

local icons = require("core.icons")
local platform = require("core.platform")

return {
  --- -------------------------------------------------------------------------
  --- Colourscheme
  --- -------------------------------------------------------------------------
  --- The one eager plugin here (besides snacks, below). A colourscheme has to
  --- be applied before the first frame draws, or you get a flash of the
  --- default theme -- so `lazy = false, priority = 1000` is the correct,
  --- deliberate exception to "everything lazy loads".
  ---
  --- rose-pine, nordic and nvim-256noir were all installed in the old config
  --- and never actually selected. Each one is startup cost (file read, Lua
  --- parse, highlight group setup) paid on every boot for zero benefit, so
  --- they were removed rather than carried forward "just in case".
  {
    "oskarnurm/koda.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("koda").setup()
      vim.cmd.colorscheme("koda")
    end,
  },

  --- -------------------------------------------------------------------------
  --- snacks.nvim -- the load-bearing plugin
  --- -------------------------------------------------------------------------
  --- One plugin, many modules: dashboard, picker (replaces telescope),
  --- explorer (replaces neo-tree), image, notifier, indent guides, scope
  --- highlighting, smooth scroll, statuscolumn, bigfile/quickfile fast paths,
  --- word-under-cursor highlighting, lazygit, and vim.ui.input. Also eager
  --- (`lazy = false, priority = 1000`) because the dashboard has to be the
  --- first thing on screen -- if it lazy-loaded on an event, you'd see a
  --- blank buffer for a frame, then the dashboard popping in late.
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    keys = {
      --- Bare, no-prefix keys. These are muscle memory from every other
      --- editor, so they don't get a which-key group -- they're meant to be
      --- typed without thinking, not discovered.
      { "<leader><space>", function() Snacks.picker.files() end, desc = "Find files" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep (project)" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command history" },
      { "<leader>e", function() Snacks.explorer() end, desc = "Explorer (toggle)" },
      { "<leader>.", function() Snacks.scratch() end, desc = "Toggle scratch buffer" },
      { "<leader>S", function() Snacks.scratch.select() end, desc = "Select scratch buffer" },
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },

      --- <leader>f -- file/find. Overlaps conceptually with <leader>s below;
      --- the split is "f is about files as objects" (open/recent/config),
      --- "s is about searching inside things" (grep/lines/symbols).
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find config file" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find buffer" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Find project" },

      --- <leader>s -- search.
      { "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep (project)" },
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer lines" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "Help pages" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
      { "<leader>sr", function() Snacks.picker.resume() end, desc = "Resume last search" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo history" },
      { "<leader>sc", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlight groups" },
      { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "Man pages" },

      --- <leader>n is notebook's (ipynb.nvim), NOT free here -- so notification
      --- history moves under <leader>u (ui/toggle) instead of the more obvious
      --- <leader>n. See the collision note in keymap-tree.lua for the pattern.
      { "<leader>un", function() Snacks.notifier.show_history() end, desc = "Notification history" },

      --- VS Code compatibility layer. Duplicates of the maps above under the
      --- key combos VS Code users' fingers already know. <C-b> and <C-p> are
      --- listed as "reference only" in keymap-tree.lua; this spec is where
      --- they're actually bound.
      { "<C-p>", function() Snacks.picker.files() end, desc = "Find files (VS Code)" },
      { "<C-S-p>", function() Snacks.picker.commands() end, desc = "Command palette (VS Code)" },
      { "<C-S-f>", function() Snacks.picker.grep() end, desc = "Find in files (VS Code)" },
      { "<C-b>", function() Snacks.explorer() end, desc = "Toggle sidebar (VS Code)" },

      --- <leader>u -- ui/toggle. Each of these wraps Snacks.toggle, which
      --- handles the "show current state in which-key" bit automatically.
      {
        "<leader>uf",
        function()
          Snacks.toggle({
            name = "Autoformat",
            get = function() return vim.g.autoformat end,
            set = function(state) vim.g.autoformat = state end,
          }):toggle()
        end,
        desc = "Toggle autoformat",
      },
      {
        "<leader>uF",
        function()
          Snacks.toggle({
            name = "Autoformat (buffer)",
            get = function() return vim.b.autoformat end,
            set = function(state) vim.b.autoformat = state end,
          }):toggle()
        end,
        desc = "Toggle autoformat (buffer)",
      },
      { "<leader>us", function() Snacks.toggle.option("spell", { name = "Spelling" }):toggle() end, desc = "Toggle spelling" },
      { "<leader>uw", function() Snacks.toggle.option("wrap", { name = "Wrap" }):toggle() end, desc = "Toggle wrap" },
      {
        "<leader>uL",
        function() Snacks.toggle.option("relativenumber", { name = "Relative number" }):toggle() end,
        desc = "Toggle relative number",
      },
      { "<leader>ud", function() Snacks.toggle.diagnostics():toggle() end, desc = "Toggle diagnostics" },
      { "<leader>ul", function() Snacks.toggle.option("number", { name = "Number" }):toggle() end, desc = "Toggle line number" },
      { "<leader>uc", function() Snacks.toggle.option("conceallevel", { off = 0, on = 2 }):toggle() end, desc = "Toggle conceal" },
      { "<leader>uT", function() Snacks.toggle.treesitter():toggle() end, desc = "Toggle treesitter highlight" },
      { "<leader>ub", function() Snacks.toggle.option("background", { off = "light", on = "dark" }):toggle() end, desc = "Toggle background" },
      { "<leader>ug", function() Snacks.toggle.indent():toggle() end, desc = "Toggle indent guides" },
      { "<leader>uh", function() Snacks.toggle.inlay_hints():toggle() end, desc = "Toggle inlay hints" },
      { "<leader>uD", function() Snacks.toggle.dim():toggle() end, desc = "Toggle dim (focus)" },
    },
    opts = {
      --- Dashboard. Layout preserved verbatim from the old config: a "keys"
      --- section (your own quick-action shortcuts) up top, then recent files,
      --- then known projects. `header = {}` -- deliberately blank; an ASCII
      --- banner is one more thing to keep in sync with terminal width.
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

      --- Inline image rendering (for markdown/notebook buffers, and Obsidian
      --- attachments). Needs the Kitty graphics protocol, which Windows
      --- Terminal doesn't implement -- see the "KNOWN GAPS" note in
      --- core/platform.lua. Disabling the whole module there (rather than
      --- just `doc.enabled`) avoids paying even the module's setup cost on
      --- a platform that can never render anything with it.
      image = {
        enabled = not platform.is_win,
        --- Obsidian integration, carried over verbatim from the old config
        --- (plugins/snacks.lua lines 18-33). snacks.image needs to resolve
        --- an image `src` to a real path on disk; obsidian.nvim's own
        --- resolution understands vault-relative attachment links that plain
        --- relative-path resolution does not. pcall-guarded both ways: if
        --- obsidian isn't loaded, or the path isn't actually a note, fall
        --- through to snacks' default resolution instead of erroring.
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
          return nil -- fall through to default resolution
        end,
        doc = {
          enabled = true,
          inline = true,
          max_height_window_percentage = 50,
        },
      },

      --- Replaces telescope entirely.
      picker = { enabled = true },
      --- Replaces neo-tree entirely -- a VS Code-style sidebar tree, not a
      --- floating fuzzy picker.
      explorer = { enabled = true },

      --- LazyVim used to own 'statuscolumn' via a hand-written function
      --- (v:lua.LazyVim.statuscolumn()); see the note at the top of
      --- core/options.lua about why that reference was deliberately dropped.
      --- snacks.statuscolumn is the direct replacement.
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

  --- -------------------------------------------------------------------------
  --- which-key -- renders the <leader> menu
  --- -------------------------------------------------------------------------
  --- `event = "VeryLazy"`: nothing needs the popup on the very first frame,
  --- and loading it that way means it's ready well before you'd ever press
  --- <leader> and pause.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
    },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer-local keymaps",
      },
    },
    config = function(_, opts)
      require("which-key").setup(opts)
      --- keymap-tree.lua is THE file to edit to add/move/rename a <leader>
      --- group. Don't hand-roll group registration here -- that file is the
      --- single source of truth so `:h which-key` and the actual popup never
      --- drift apart.
      require("keymap-tree").setup()
    end,
  },

  --- -------------------------------------------------------------------------
  --- Statusline
  --- -------------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.section_separators = { left = "█", right = "█" }
      opts.options.component_separators = { left = "│", right = "│" }
      opts.options.globalstatus = true -- one statusline for the whole editor;
      -- pairs with opt.laststatus = 3 in core/options.lua

      --- Hand-rolled dark theme, carried over verbatim from the old config
      --- (plugins/lualine.lua lines 11-58). The stock lualine themes ship a
      --- near-white "c" (middle) section background that clashes badly with
      --- this colourscheme's dark base -- this table exists purely to fix
      --- that one section across every mode.
      local custom_theme = {
        normal = {
          a = { bg = "#4e4e4e", fg = "#ffffff", gui = "bold" },
          b = { bg = "#3a3a3a", fg = "#ffffff" },
          c = { bg = "#262626", fg = "#ffffff" },
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

      opts.sections = {
        lualine_a = { "mode" },
        lualine_b = {
          "branch",
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
          },
        },
        lualine_c = {
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {
          --- Custom: line number only, not line:column. Carried over
          --- verbatim -- the column half of "location" is rarely useful and
          --- this reads cleaner at a glance.
          function() return "L" .. vim.fn.line(".") end,
        },
      }

      return opts
    end,
  },

  --- -------------------------------------------------------------------------
  --- Tabline
  --- -------------------------------------------------------------------------
  --- VS Code-style buffer tabs. <S-h>/<S-l> (prev/next buffer) are already
  --- bound in core/keymaps.lua and work fine without this plugin loaded --
  --- they are NOT redefined here, to avoid two definitions of the same map
  --- drifting apart.
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
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- Cmdline / messages
  --- -------------------------------------------------------------------------
  --- Floating cmdline instead of the bottom-of-screen one, plus routes long
  --- messages (e.g. multi-line LSP output) into a split rather than a
  --- `:messages`-only wall of text.
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    keys = {
      { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, mode = { "i", "n", "s" }, desc = "Scroll forward (LSP doc)" },
      { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, mode = { "i", "n", "s" }, desc = "Scroll backward (LSP doc)" },
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
        bottom_search = true, -- classic bottom search bar, not floating
        command_palette = true, -- cmdline + popupmenu combined, VS Code style
        long_message_to_split = true, -- long messages -> split, not a wall of text
        lsp_doc_border = true,
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- Icon provider
  --- -------------------------------------------------------------------------
  --- mini.icons is `lazy = true`, but its `init` runs at startup regardless
  --- (init functions always run, even for lazy specs) and registers a
  --- package.preload shim for "nvim-web-devicons". Plenty of plugins
  --- `require("nvim-web-devicons")` directly rather than going through
  --- mini.icons' compat layer -- this makes that require succeed without
  --- installing the real (larger, unmaintained-relative-to-mini) plugin.
  ---
  --- This is also why core/icons.lua has no `kinds` table for LSP completion
  --- item kinds (Function, Variable, ...): mini.icons already ships a
  --- complete set and blink.cmp reads it directly, so duplicating those
  --- glyphs here would just be a second copy to keep in sync.
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

  --- -------------------------------------------------------------------------
  --- Colour column
  --- -------------------------------------------------------------------------
  --- A vertical line at 'textwidth' -- small plugin, small spec.
  {
    "lukas-reineke/virt-column.nvim",
    event = "VeryLazy",
    opts = { char = "\u{2502}" }, -- BOX DRAWINGS LIGHT VERTICAL
  },
}

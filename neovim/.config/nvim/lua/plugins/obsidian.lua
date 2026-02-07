return {
  -- which-key: Register Obsidian group
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>o", group = "obsidian", icon = "󱞁" },
      },
    },
  },

  -- Main Obsidian.nvim plugin
  {
    "epwalsh/obsidian.nvim",
    version = "*", -- Use latest release
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      -- Navigation
      { "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", desc = "Switch notes" },
      { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search vault content" },
      { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Follow wiki link" },
      { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Show backlinks" },

      -- Note creation
      { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note in inbox" },
      { "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Open today's journal" },
      { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Open yesterday's journal" },
      { "<leader>oT", "<cmd>ObsidianTomorrow<cr>", desc = "Open tomorrow's journal" },
      { "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Insert template" },

      -- Utilities
      { "<leader>ol", "<cmd>ObsidianLink<cr>", mode = "v", desc = "Link selection" },
      { "<leader>oL", "<cmd>ObsidianLinkNew<cr>", mode = "v", desc = "Create note from selection" },
      { "<leader>oc", "<cmd>ObsidianToggleCheckbox<cr>", desc = "Toggle checkbox" },
      { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Rename note & update links" },
      { "<leader>op", "<cmd>ObsidianPasteImg<cr>", desc = "Paste image" },
      { "<leader>oO", "<cmd>ObsidianOpen<cr>", desc = "Open in Obsidian app" },
    },
    opts = {
      workspaces = {
        {
          name = "main",
          path = "~/Documents/Sync/ObsidianVault",
        },
      },

      -- New notes go to inbox
      notes_subdir = "__inbox",

      -- Dynamic daily notes folder based on current year
      daily_notes = {
        folder = "misc/journal/" .. os.date("%Y"),
        date_format = "%Y-%m-%d",
        template = "misc/templates/New Daily.md",
      },

      -- Templates configuration
      templates = {
        folder = "misc/templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },

      -- Attachments configuration
      attachments = {
        img_folder = "assets",
        -- Use Obsidian-style image embedding
        img_text_func = function(client, path)
          return string.format("![[%s]]", path.name)
        end,
      },

      -- Disable UI (let render-markdown.nvim handle rendering)
      ui = {
        enable = false,
      },

      -- Use telescope for pickers
      picker = {
        name = "telescope.nvim",
        mappings = {
          new = "<C-x>",
          insert_link = "<C-l>",
        },
      },

      -- Completion with nvim-cmp
      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },

      -- Wiki-style links (Obsidian default)
      preferred_link_style = "wiki",

      -- Follow link behavior
      follow_url_func = function(url)
        -- Open URLs in default browser
        vim.fn.jobstart({ "open", url })
      end,

      -- Note ID generation (use title as filename)
      note_id_func = function(title)
        -- Convert title to valid filename
        if title ~= nil then
          -- Replace spaces with hyphens, remove special chars
          return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          -- If no title, use timestamp
          return tostring(os.time())
        end
      end,

      -- Note frontmatter
      note_frontmatter_func = function(note)
        local out = {
          id = note.id,
          aliases = note.aliases,
          tags = note.tags,
          created = os.date("%Y-%m-%d %H:%M"),
        }

        -- Preserve existing frontmatter
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,

      -- Disable diagnostics for certain warnings
      disable_frontmatter = false,

      -- Markdown extensions
      yaml_parser = "native",
    },
  },

  -- nvim-cmp integration for markdown files only
  {
    "hrsh7th/nvim-cmp",
    optional = true,
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    opts = function(_, opts)
      -- Add Obsidian sources for markdown files
      local cmp = require("cmp")

      cmp.setup.filetype("markdown", {
        sources = cmp.config.sources({
          { name = "obsidian" },
          { name = "obsidian_new" },
          { name = "obsidian_tags" },
          { name = "path" },
          { name = "buffer" },
        }),
      })

      return opts
    end,
  },

  -- Telescope.nvim for Obsidian note navigation
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
}

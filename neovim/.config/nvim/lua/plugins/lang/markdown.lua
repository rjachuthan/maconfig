local platform = require("core.platform")

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "md" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    keys = {
      {
        "<leader>um",
        function()
          require("render-markdown").toggle()
        end,
        desc = "Toggle markdown rendering",
        ft = { "markdown", "md" },
      },
    },
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    opts = { servers = { marksman = {} } },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdownlint-cli2" })
      return opts
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { markdown = { "prettier", "markdownlint-cli2" } } },
  },
  {
    "mfussenegger/nvim-lint",
    opts = { linters_by_ft = { markdown = { "markdownlint-cli2" } } },
  },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    cond = platform.has("node"),
    build = "cd app && npx --yes yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    keys = {
      { "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview", ft = "markdown" },
    },
  },

  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    cond = platform.obsidian_vault() ~= nil,
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", desc = "Switch notes" },
      { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search vault content" },
      { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Follow link" },
      { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Backlinks" },
      { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note" },
      { "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Today's daily note" },
      { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Yesterday's daily note" },
      { "<leader>oT", "<cmd>ObsidianTomorrow<cr>", desc = "Tomorrow's daily note" },
      { "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Insert template" },
      { "<leader>oc", "<cmd>ObsidianToggleCheckbox<cr>", desc = "Toggle checkbox" },
      { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Rename note & update links" },
      { "<leader>op", "<cmd>ObsidianPasteImg<cr>", desc = "Paste image" },
      { "<leader>oO", "<cmd>ObsidianOpen<cr>", desc = "Open in Obsidian app" },
      { "<leader>ol", "<cmd>ObsidianLink<cr>", mode = "v", desc = "Link selection" },
      { "<leader>oL", "<cmd>ObsidianLinkNew<cr>", mode = "v", desc = "Create note from selection" },
    },
    opts = {
      workspaces = {
        {
          name = "main",
          path = platform.obsidian_vault() or "~",
        },
      },

      notes_subdir = "__inbox",

      daily_notes = {
        folder = function()
          return "misc/journal/" .. os.date("%Y")
        end,
        date_format = "%Y-%m-%d",
        template = "misc/templates/New Daily.md",
      },

      templates = {
        folder = "misc/templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },

      attachments = {
        img_folder = "assets",
        img_text_func = function(_, path)
          local name = vim.fs.basename(tostring(path))
          local encoded_name = require("obsidian.util").urlencode(name)
          return string.format("![%s](%s)", name, encoded_name)
        end,
      },
      ui = { enable = false },
      picker = {
        name = "snacks.nvim",
        mappings = {
          new = "<C-x>",
          insert_link = "<C-l>",
        },
      },
      completion = {
        nvim_cmp = false,
        blink = true,
        min_chars = 2,
      },

      preferred_link_style = "wiki",

      follow_url_func = function(url)
        platform.open_url(url)
      end,

      note_id_func = function(title)
        if title ~= nil then
          return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        end
        return tostring(os.time())
      end,

      note_frontmatter_func = function(note)
        local out = {
          id = note.id,
          aliases = note.aliases,
          tags = note.tags,
          created = os.date("%Y-%m-%d %H:%M"),
        }
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,

      disable_frontmatter = false,
      yaml_parser = "native",
    },
  },
}

--- ===========================================================================
--- MARKDOWN + OBSIDIAN
--- ===========================================================================
--- Markdown rendering/preview/lint/format, plus a full Obsidian vault
--- workflow. All `ft = "markdown"` (or a superset) -- nothing here has any
--- business loading before you open a .md file.
--- ===========================================================================

local platform = require("core.platform")

return {
  --- -------------------------------------------------------------------------
  --- render-markdown.nvim -- in-buffer rendering (headings, tables, code
  --- fences) without leaving Neovim for a browser preview.
  --- -------------------------------------------------------------------------
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

  --- -------------------------------------------------------------------------
  --- marksman -- LSP (headings/links/references, works across a vault)
  --- -------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {},
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- Mason: markdownlint-cli2 is a linter, not an LSP server -- not covered
  --- by mason-lspconfig's auto-install from opts.servers above.
  --- -------------------------------------------------------------------------
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "markdownlint-cli2" })
      return opts
    end,
  },

  --- -------------------------------------------------------------------------
  --- conform.nvim + nvim-lint: prettier for prose formatting, markdownlint-cli2
  --- for style rules (line length, heading levels, etc.). markdownlint-cli2
  --- auto-discovers .markdownlint.json / .markdownlint.jsonc up the directory
  --- tree, so per-vault or per-project rule overrides just work with no
  --- config here.
  --- -------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettier", "markdownlint-cli2" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint-cli2" },
      },
    },
  },

  --- -------------------------------------------------------------------------
  --- markdown-preview.nvim -- full browser preview
  --- -------------------------------------------------------------------------
  --- The build step shells out to yarn to install the preview app's JS
  --- dependencies. `npx --yes yarn install` (rather than a bare `yarn
  --- install`, or the old cd-and-run-a-.sh-script form) works identically on
  --- macOS and Windows and doesn't require yarn to be globally installed --
  --- just node/npx. `cond` on `platform.has("node")` so the whole plugin is
  --- skipped rather than erroring on a machine with no Node at all.
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

  --- -------------------------------------------------------------------------
  --- obsidian.nvim -- Obsidian vault integration
  --- -------------------------------------------------------------------------
  --- `obsidian-nvim/obsidian.nvim`, NOT `epwalsh/obsidian.nvim`. The latter
  --- (what the old config used) is archived/unmaintained upstream; this is
  --- the community-maintained fork that continues receiving fixes.
  ---
  --- THREE BUGS FIXED from the old config's plugins/obsidian.lua:
  ---
  --- (a) The old file did `if vim.fn.has("win32") == 1 then return {} end` at
  ---     the top -- Obsidian was unconditionally DISABLED on Windows, full
  ---     stop, regardless of whether a vault actually existed there. Instead,
  ---     `cond` below is gated on `platform.obsidian_vault()` returning a
  ---     real path, which is computed per-machine (env var override, then
  ---     OS-conventional locations) and works identically on both platforms.
  ---
  --- (b) `follow_url_func` shelled out directly to macOS-only `open`. Now
  ---     routes through `platform.open_url()`, which uses `vim.ui.open`
  ---     (works everywhere Neovim 0.10+ runs) with a manual per-OS fallback.
  ---
  --- (c) `daily_notes.folder = "misc/journal/" .. os.date("%Y")` was a
  ---     STRING, evaluated exactly once when this file was first required.
  ---     In a long-running Neovim session that survives a New Year, every
  ---     daily note after January 1st would still resolve to the previous
  ---     year's folder. It's a function now, evaluated fresh on every call.
  ---
  --- COUPLING WARNING: `img_text_func` below urlencodes attachment basenames
  --- specifically so snacks.nvim can resolve and inline-render vault images.
  --- The other half of this integration is `image.resolve` in
  --- plugins/ui.lua, which calls `obsidian.api.resolve_attachment_path` on
  --- exactly this encoded form. Changing the encoding here without updating
  --- that resolver (or vice versa) silently breaks image previews in notes --
  --- they are two ends of the same handshake, not independent settings.
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
          --  Resolved lazily by the plugin itself from `cond` having already
          --  confirmed a vault exists; falling back to "~" is unreachable in
          --  practice but keeps the type non-optional.
          path = platform.obsidian_vault() or "~",
        },
      },

      notes_subdir = "__inbox",

      --- Function, not a string -- see fix (c) above.
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
        --- See the COUPLING WARNING above: paired with plugins/ui.lua's
        --- `image.resolve`.
        img_text_func = function(_, path)
          local name = vim.fs.basename(tostring(path))
          local encoded_name = require("obsidian.util").urlencode(name)
          return string.format("![%s](%s)", name, encoded_name)
        end,
      },

      --- render-markdown.nvim (above) owns rendering; don't let obsidian's
      --- own concealer fight it over the same buffer.
      ui = { enable = false },

      --- snacks.picker replaces telescope entirely in this config (see
      --- plugins/ui.lua) -- there is no telescope.nvim installed to point at.
      picker = {
        name = "snacks.nvim",
        mappings = {
          new = "<C-x>",
          insert_link = "<C-l>",
        },
      },

      --- This config runs blink.cmp, not nvim-cmp -- see fix (b) in
      --- lang/sql.lua's header for the sibling bug this pattern already
      --- caused once (a dead nvim-cmp source registration). Obsidian's fork
      --- has native blink support, so there's no dead code to write here.
      completion = {
        nvim_cmp = false,
        blink = true,
        min_chars = 2,
      },

      preferred_link_style = "wiki",

      --- Fix (b): platform.open_url uses vim.ui.open, not a hardcoded macOS
      --- `open` call.
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
        --- Preserve any frontmatter that already existed on the note (e.g.
        --- hand-edited fields) rather than clobbering it.
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

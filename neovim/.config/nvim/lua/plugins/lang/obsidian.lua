local platform = require("core.platform")

-- Resolves an image path referenced from a note, handling three cases Obsidian
-- allows: a path relative to the note itself, a path relative to the vault
-- root, and a bare filename (Obsidian searches the whole vault for these).
local function resolve_vault_image_path(file_path, image_url, resolve_relative)
  local vault = platform.obsidian_vault()
  if not vault then
    return resolve_relative(file_path, image_url)
  end
  if image_url:sub(1, 1) == "/" or image_url:sub(1, 1) == "~" then
    return resolve_relative(file_path, image_url)
  end

  local relative_to_note = resolve_relative(file_path, image_url)
  if vim.fn.filereadable(relative_to_note) == 1 then
    return relative_to_note
  end

  local relative_to_vault = vault .. "/" .. image_url
  if vim.fn.filereadable(relative_to_vault) == 1 then
    return relative_to_vault
  end

  local basename = vim.fs.basename(image_url)
  local matches = vim.fn.globpath(vault, "**/" .. basename, false, true)
  if matches[1] then
    return matches[1]
  end

  return relative_to_note
end

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    cond = platform.obsidian_vault() ~= nil,
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Switch notes" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search vault content" },
      { "<leader>of", "<cmd>Obsidian follow_link<cr>", desc = "Follow link" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>od", "<cmd>Obsidian today<cr>", desc = "Today's daily note" },
      { "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Yesterday's daily note" },
      { "<leader>oT", "<cmd>Obsidian tomorrow<cr>", desc = "Tomorrow's daily note" },
      { "<leader>ot", "<cmd>Obsidian template<cr>", desc = "Insert template" },
      { "<leader>oc", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Toggle checkbox" },
      { "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Rename note & update links" },
      { "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Paste image" },
      { "<leader>oO", "<cmd>Obsidian open<cr>", desc = "Open in Obsidian app" },
      { "<leader>ol", "<cmd>Obsidian link<cr>", mode = "v", desc = "Link selection" },
      { "<leader>oL", "<cmd>Obsidian link_new<cr>", mode = "v", desc = "Create note from selection" },
    },
    opts = {
      legacy_commands = false,

      workspaces = {
        {
          name = "main",
          path = platform.obsidian_vault() or "~",
        },
      },

      notes_subdir = "__inbox",

      daily_notes = {
        folder = "misc/journal/" .. os.date("%Y"),
        date_format = "%Y-%m-%d",
        template = "misc/templates/New Daily.md",
      },

      templates = {
        folder = "misc/templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },

      attachments = {
        folder = "assets",
        img_text_func = function(path)
          local name = vim.fs.basename(tostring(path))
          local encoded_name = require("obsidian.util").urlencode(name)
          return string.format("![%s](%s)", name, encoded_name)
        end,
      },
      ui = { enable = false },
      picker = {
        name = "snacks.picker",
        note_mappings = {
          new = "<C-x>",
          insert_link = "<C-l>",
        },
      },
      completion = {
        min_chars = 2,
      },

      link = { style = "wiki" },

      open = {
        func = function(uri)
          platform.open_url(uri)
        end,
      },

      note_id_func = function(title)
        if title ~= nil then
          return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        end
        return tostring(os.time())
      end,

      frontmatter = {
        enabled = true,
        func = function(note)
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
      },
    },
  },

  -- Render Obsidian's ![[wikilink]] image embeds, not just standard
  -- markdown ![](path) images, and resolve them the way Obsidian does
  -- (relative to the note, relative to the vault root, or by bare filename).
  {
    "3rd/image.nvim",
    opts = function(_, opts)
      if not platform.obsidian_vault() then
        return opts
      end

      opts.integrations = opts.integrations or {}

      if opts.integrations.markdown then
        opts.integrations.markdown.resolve_image_path = resolve_vault_image_path
      end

      opts.integrations.obsidian = {
        enabled = true,
        resolve_image_path = resolve_vault_image_path,
      }

      return opts
    end,
  },
}

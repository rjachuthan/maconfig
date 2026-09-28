-- Custom image.nvim integration for Obsidian's `![[wikilink]]` embed syntax.
-- The markdown treesitter grammar doesn't parse `![[...]]` as an image node
-- (that's Obsidian's own syntax, not standard markdown), so image.nvim's
-- built-in "markdown" integration never sees these embeds. This integration
-- scans buffer text directly instead of relying on treesitter.
local document = require("image/utils/document")

local image_extensions = {
  png = true,
  jpg = true,
  jpeg = true,
  gif = true,
  bmp = true,
  webp = true,
  tiff = true,
}

return document.create_document_integration({
  name = "obsidian",
  default_options = {
    clear_in_insert_mode = false,
    download_remote_images = false,
    only_render_image_at_cursor = false,
    filetypes = { "markdown" },
  },
  query_buffer_images = function(buffer)
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    local images = {}

    for row, line in ipairs(lines) do
      local search_from = 1
      while true do
        local s, e, inner = line:find("!%[%[(.-)%]%]", search_from)
        if not s then
          break
        end

        local target = vim.trim((inner:match("^([^|]+)")) or inner)
        local ext = target:match("%.([%a%d]+)$")
        if ext and image_extensions[ext:lower()] then
          table.insert(images, {
            node = nil,
            range = {
              start_row = row - 1,
              start_col = s - 1,
              end_row = row - 1,
              end_col = e,
            },
            url = target,
          })
        end

        search_from = e + 1
      end
    end

    return images
  end,
})

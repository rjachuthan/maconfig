return {
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        -- Obsidian integration: resolve image paths correctly
        resolve = function(path, src)
          -- Safely check if obsidian.nvim is loaded
          local ok, api = pcall(require, "obsidian.api")
          if ok and api then
            -- Only resolve if this is actually an Obsidian note
            local is_note_ok, is_note = pcall(api.path_is_note, path)
            if is_note_ok and is_note then
              local resolved_ok, resolved = pcall(api.resolve_attachment_path, src)
              if resolved_ok then
                return resolved
              end
            end
          end
          -- Return nil to use default resolution
          return nil
        end,
        -- Document rendering settings
        doc = {
          enabled = true,
          inline = true,
          max_width = nil,
          max_height_window_percentage = 50,
        },
      },
    },
  },
}

-- Initialize Configuration
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local opacity = 0.85
-- local transparent_bg = "rgba(22, 24, 26, " .. opacity .. ")"

-- Font
config.font = wezterm.font_with_fallback({
	{
		family = "0xProto Nerd Font",
		weight = "Regular",
	},
	"SF Pro",
})
config.font_size = 16
config.line_height = 1.2

-- Colors
config.color_scheme = "Nucolors (terminal.sexy)"

-- Window
-- config.initial_rows = 45
-- config.initial_cols = 180
config.window_decorations = "RESIZE"
config.window_background_opacity = opacity
config.macos_window_background_blur = 100
config.window_close_confirmation = "NeverPrompt"
config.win32_system_backdrop = "Acrylic"
-- config.max_fps = 144
-- config.animation_fps = 60
-- config.cursor_blink_rate = 250

config.window_padding = {
	left = 50,
	right = 50,
	top = 20,
	bottom = 50,
}

-- Tabs
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = false
config.use_fancy_tab_bar = true

-- Keybindings
config.keys = {
	-- Remap paste for clipboard history compatibility
	-- { key = "v", mods = "CTRL", action = wezterm.action({ PasteFrom = "Clipboard" }) },
	{ key = '"', mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "%", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "8", mods = "CTRL", action = wezterm.action.PaneSelect },
	{ key = "h", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CTRL", action = wezterm.action.ActivatePaneDirection("Right") },
}

return config

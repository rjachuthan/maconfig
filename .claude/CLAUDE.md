# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS dotfiles management system with dynamic theme switching capabilities. The system uses GNU Stow for symlink management and a custom color scheme system inspired by pywal.

## Architecture

### Three-Layer Color System
1. **Color schemes** (`colors/`) - Minimal 16-color theme files (pywal format)
2. **Base configurations** - Non-color settings (opacity, blur, spacing, fonts) shared across themes
3. **Application templates** - Per-app configs that consume colors and base settings to generate final configs

### Repository Structure (GNU Stow Compatible)
Each application is a separate "stow package" that mirrors home directory structure:
- `aerospace/` - Window manager
- `sketchybar/` - Status bar
- `neovim/` - Text editor
- `tmux/` - Terminal multiplexer
- `zsh/` - Shell (configs go to `~/.config/zsh/`, not home)
- `yazi/` - File manager
- `skhd/` - Hotkey daemon
- `hammerspoon/` - Automation
- `wezterm/` or `kitty/` - Terminal emulator
- `jankyborders/` - Window borders

### Key Design Decisions
- ZSH configuration lives in `~/.config/zsh/` (requires `/etc/zshenv` to set ZDOTDIR)
- Theme files contain ONLY 16 terminal colors (color0-color15), no app-specific settings
- Colors are mapped to semantic names (background, foreground, accent, success, warning, error, etc.) for templates
- Each stow package must be independently stowable without conflicts

## Theme System

### Theme Variants
- **shiny-black** - Primary theme (deep black with purple/magenta accents)
- **shiny-black-cool** - Cyan/blue accents
- **shiny-black-warm** - Orange/coral accents
- **shiny-black-high-contrast** - Boosted text brightness
- **shiny-black-low-contrast** - Softer contrast
- **flexoki** - Dark and light variants
- **poimandres**

### Theme Switching
The theme switcher must:
1. Validate theme exists
2. Generate all app configs from templates using the selected color scheme
3. Reload affected applications (Sketchybar, JankyBorders, terminal, Neovim if running, Tmux if running)
4. Track currently active theme

## Dependencies

- GNU Stow (symlink management)
- yq (YAML processor for configs)
- Homebrew (package management)
- Python 3 (optional, for generator scripts)

## Sketchybar Configuration (Refactored)

### Architecture
The Sketchybar configuration has been refactored into a modular, maintainable architecture following SOLID principles:

```
.config/sketchybar/
├── config.sh              # Central configuration (paths, constants)
├── sketchybarrc           # Main entry point
├── lib/                   # Shared utility libraries
│   ├── common.sh         # Core functions (range selection, item updates, etc.)
│   ├── ui.sh             # UI rendering (visibility, animations, sliders)
│   ├── events.sh         # Event handling (subscriptions, mouse, debouncing)
│   ├── state.sh          # State management (persistent, session, caching)
│   └── icons.sh          # Icon map wrapper
├── theme/                # Visual definitions
│   ├── colors.sh         # Color constants (Catppuccin Macchiato)
│   └── sf-symbols.sh     # SF Symbols icon constants
├── modules/              # Feature modules (organized by category)
│   ├── apps/             # front_app, spotify
│   ├── integrations/     # brew, github
│   ├── system/           # battery, cpu, volume
│   ├── ui/               # apple, calendar, zen
│   └── workspace/        # spaces, yabai
├── utils/                # Helper utilities
│   ├── icon_map.sh       # App icon mapping
│   └── app_icons.lua     # Icon data
└── native/               # C native code
    ├── helper (binary)   # Mach helper for CPU monitoring
    └── [source files]
```

### Module Structure
Each feature is implemented as a pair of files:
- `*.item.sh` - Sketchybar item configuration (creates UI elements)
- `*.plugin.sh` - Event handler and logic (responds to events, updates display)

**Example: Battery Module**
```bash
modules/system/battery.item.sh    # Creates battery item with configuration
modules/system/battery.plugin.sh   # Handles updates, uses select_icon_by_range()
```

### Core Library Functions

**Range-based selection** (`lib/common.sh`):
- `select_icon_by_range VALUE "MIN-MAX:ICON" ...` - Select icon by value ranges
- `select_color_by_range VALUE "MIN-MAX:COLOR" ...` - Select color by ranges
- `select_by_range VALUE "MIN-MAX:VALUE" ...` - Generic range selector

**Item management**:
- `update_item ITEM_NAME key=value ...` - Update item properties
- `batch_update args...` - Batch update multiple items
- `query_item ITEM_NAME PROPERTY` - Get item property value

**UI operations** (`lib/ui.sh`):
- `show_item / hide_item / toggle_item ITEM_NAME` - Control visibility
- `set_icon / set_label / set_color ITEM_NAME VALUE` - Set display
- `animate_item CURVE DURATION ITEM_NAME props...` - Animate changes
- `highlight_item ITEM_NAME` - Toggle highlight state
- `update_slider ITEM_NAME PERCENTAGE [WIDTH]` - Update slider display

**Event handling** (`lib/events.sh`):
- `subscribe_event ITEM_NAME EVENT` - Subscribe to events
- `trigger_event EVENT_NAME` - Trigger custom event
- `dispatch_event SENDER handlers_array` - Dispatch to handlers
- `debounce DELAY FUNCTION [ARGS]` - Debounce function calls
- `throttle INTERVAL FUNCTION [ARGS]` - Throttle function calls

**State management** (`lib/state.sh`):
- `save_state KEY VALUE` - Save persistent state to file
- `load_state KEY [DEFAULT]` - Load state from file
- `cache_set KEY VALUE TTL_SECONDS` - Cache with TTL
- `cache_get KEY` - Get cached value (returns empty if expired)
- `is_zen_mode / enable_zen_mode / disable_zen_mode` - Zen mode helpers
- `set_session / get_session` - In-memory session state

**Icon management** (`lib/icons.sh`):
- `get_app_icon APP_NAME` - Get icon from icon map
- `get_app_icon_cached APP_NAME` - Get icon with caching
- `get_icon_with_fallback APP_NAME FALLBACK` - Get with fallback
- `get_system_icon APP_NAME` - Get system app icon
- `clear_icon_cache` - Clear cached icons

### Configuration

**Central config** (`config.sh`):
- All paths defined once: `CONFIG_DIR`, `LIB_DIR`, `THEME_DIR`, `MODULE_DIR`, `UTILS_DIR`, `NATIVE_DIR`
- All constants: `FONT`, `PADDINGS`, `BAR_*` settings
- Helper settings: `HELPER_NAME`
- Automatically sources all libraries and themes

**Usage in modules**:
```bash
#!/bin/bash
source "$CONFIG_DIR/config.sh"

# Now have access to:
# - All colors: $RED, $BLUE, $GREEN, etc.
# - All icons: $BATTERY_100, $VOLUME_100, etc.
# - All lib functions
# - All settings: $FONT, $PADDINGS, etc.
```

### Adding New Modules

1. **Create item configuration**:
   ```bash
   # modules/category/myfeature.item.sh
   source "$CONFIG_DIR/config.sh"
   sketchybar --add item myfeature right \
              --set myfeature script="$MODULE_DIR/category/myfeature.plugin.sh" \
                              icon=$ICON_NAME
   ```

2. **Create plugin handler**:
   ```bash
   # modules/category/myfeature.plugin.sh
   source "$CONFIG_DIR/config.sh"

   update() {
     # Use lib functions
     local icon=$(select_icon_by_range $VALUE "0-50:$ICON_LOW" "51-100:$ICON_HIGH")
     update_item "$NAME" icon="$icon"
   }

   case "$SENDER" in
     "routine") update ;;
   esac
   ```

3. **Add to sketchybarrc**:
   ```bash
   source "$MODULE_DIR/category/myfeature.item.sh"
   ```

### Critical Bug Fixes
- ✅ Fixed missing `github.item.sh` sourcing in sketchybarrc
- ✅ Resolved `helper/` vs `helpers/` naming confusion → `native/` vs `utils/`
- ✅ Eliminated ~300 lines of duplication across modules

### Zen Mode
Central item list for zen mode is defined in `lib/state.sh`:
```bash
get_zen_items()  # Returns: "calendar brew battery volume cpu"
```
Edit this function to change which items hide in zen mode.

### Performance Optimizations
- Icon caching to avoid repeated icon map lookups
- State caching with TTL for expensive operations
- Debouncing for high-frequency events
- Throttling for animations and updates

## Fonts

- Monospace: JetBrains Mono (with ligatures)
- Sans-serif: SF Pro
- Sizes: 13pt normal, 12pt for bars
- Sketchybar app font: `sketchybar-app-font` (auto-generated)

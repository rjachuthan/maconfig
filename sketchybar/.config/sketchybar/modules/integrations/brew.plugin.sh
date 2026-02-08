#!/usr/bin/env bash

# Brew Module - Plugin
# Updates count and color based on number of outdated packages

# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

update() {
  # Work around Homebrew environment bug by calling through a login shell
  # (Homebrew crashes with "undefined method 'success?' for nil" when run directly from sketchybar)
  local count=$(/bin/zsh -l -c "brew outdated --quiet 2>/dev/null" | wc -l | tr -d ' ')

  # Select color based on number of outdated packages
  local color=$(select_color_by_range "$count" \
    "0:$GREEN" \
    "1-9:$WHITE" \
    "10-29:$YELLOW" \
    "30-59:$ORANGE" \
    "60-999:$RED")

  # Show checkmark when everything is up to date
  local label="$count"
  [[ "$count" == "0" ]] && label="􀆅"

  update_item "$NAME" label="$label" icon.color="$color" label.color="$color"
}

update

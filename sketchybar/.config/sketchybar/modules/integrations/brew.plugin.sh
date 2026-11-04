#!/bin/bash

# Brew Module - Plugin
# Updates count and color based on number of outdated packages

source "$CONFIG_DIR/config.sh"

# Only show the item when outdated packages exceed this number
BREW_SHOW_THRESHOLD=15

update() {
  # Work around Homebrew environment bug by calling through a login shell
  # (Homebrew crashes with "undefined method 'success?' for nil" when run directly from sketchybar)
  local count=$(/bin/zsh -l -c "brew outdated --quiet 2>/dev/null" | wc -l | tr -d ' ')

  local color=$(select_color_by_range "$count" \
    "0-29:$YELLOW" \
    "30-59:$ORANGE" \
    "60-9999:$RED")

  local drawing="off"
  (( count > BREW_SHOW_THRESHOLD )) && ! is_zen_mode && drawing="on"

  update_item "$NAME" drawing="$drawing" label="$count" icon.color="$color" label.color="$color"
}

update

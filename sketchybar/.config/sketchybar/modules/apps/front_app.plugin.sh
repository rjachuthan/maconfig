#!/bin/bash

# Front App Module - Plugin
# Updates the front app display with icon from icon map


# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

update() {
  if [[ "$SENDER" == "front_app_switched" ]]; then
    local icon=$(get_app_icon "$INFO")
    update_item "$NAME" label="$INFO" icon="$icon"
  fi
}

update

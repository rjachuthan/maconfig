#!/bin/bash

# Brew Module - Plugin
# Updates count and color based on number of outdated packages

source "$CONFIG_DIR/config.sh"

update() {
  local count=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')

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

  update_item "$NAME" label="$label" icon.color="$color"
}

update

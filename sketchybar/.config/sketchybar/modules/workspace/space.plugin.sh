#!/bin/bash

# Space Module - Plugin
# Updates individual space highlighting and app icons

source "$CONFIG_DIR/config.sh"

update() {
  # Get current aerospace workspace
  local focused_workspace=$(aerospace list-workspaces --focused 2>/dev/null)

  # Extract space number from item name (space.X -> X)
  local sid=$(echo "$NAME" | sed 's/space\.//')

  local selected="false"
  [[ "$sid" == "$focused_workspace" ]] && selected="true"

  # Show label width only for selected workspace
  local width="dynamic"
  [[ "$selected" == "true" ]] && width="0"

  sketchybar --animate tanh 20 --set "$NAME" icon.highlight="$selected" label.width="$width"

  # Update zen mode space visibility if in zen mode
  update_zen_spaces
}

mouse_clicked() {
  local sid=$(echo "$NAME" | sed 's/space\.//')

  if [[ "$BUTTON" == "right" ]]; then
    trigger_event aerospace_workspace_change
  else
    # Focus workspace with aerospace
    aerospace workspace "$sid" 2>/dev/null
    trigger_event aerospace_workspace_change
  fi
}

# Dispatch events
case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  *) update ;;
esac

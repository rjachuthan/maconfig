#!/bin/bash

# Space Module - Plugin
# Updates the single workspace indicator with the focused aerospace workspace name

# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

update() {
  local focused_workspace
  focused_workspace=$(aerospace list-workspaces --focused 2>/dev/null)
  sketchybar --animate tanh 20 --set current_workspace label="$focused_workspace"
}

mouse_clicked() {
  trigger_event aerospace_workspace_change
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  *) update ;;
esac

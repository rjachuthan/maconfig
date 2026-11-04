#!/bin/bash

# Spaces Module - Item Configuration
# Displays a single box showing the currently focused aerospace workspace

# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

# Register aerospace workspace change event
sketchybar --add event aerospace_workspace_change

sketchybar --add item        current_workspace left                          \
           --set current_workspace                                            \
                             icon.drawing=off                                 \
                             label.font="$FONT:Bold:13.0"                    \
                             label.color=$WHITE                               \
                             label.padding_left=12                            \
                             label.padding_right=0                            \
                             padding_left=0                                   \
                             padding_right=0                                  \
                             background.drawing=off                           \
                             script="$MODULE_DIR/workspace/space.plugin.sh"  \
           --subscribe       current_workspace aerospace_workspace_change     \
                                               mouse.clicked

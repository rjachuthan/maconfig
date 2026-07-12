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
                             label.padding_right=12                           \
                             padding_left=4                                   \
                             padding_right=15                                 \
                             background.color=$BACKGROUND_1                   \
                             background.border_color=$BACKGROUND_2            \
                             background.border_width=2                        \
                             background.corner_radius=8                       \
                             background.height=26                             \
                             background.drawing=on                            \
                             script="$MODULE_DIR/workspace/space.plugin.sh"  \
           --subscribe       current_workspace aerospace_workspace_change     \
                                               mouse.clicked

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
                             label.padding_left=10                            \
                             label.padding_right=10                           \
                             padding_left=2                                   \
                             padding_right=6                                  \
                             background.color=$BACKGROUND_1                   \
                             background.border_color=$BACKGROUND_2            \
                             background.border_width=1                        \
                             background.corner_radius=$BACKGROUND_CORNER_RADIUS                      \
                             background.height=$BACKGROUND_HEIGHT                         \
                             background.drawing=on                            \
                             script="$MODULE_DIR/workspace/space.plugin.sh"  \
           --subscribe       current_workspace aerospace_workspace_change     \
                                               mouse.clicked

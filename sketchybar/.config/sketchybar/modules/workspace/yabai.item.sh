#!/bin/bash

# Yabai Module - Item Configuration
# Displays window manager state (works with both yabai and aerospace)

source "$CONFIG_DIR/config.sh"

sketchybar --add       event        window_focus                  \
           --add       event        windows_on_spaces             \
           --add       item         system.yabai left             \
           --set       system.yabai script="$MODULE_DIR/workspace/yabai.plugin.sh" \
                                    icon.font="$FONT:Bold:16.0"   \
                                    label.drawing=off             \
                                    icon.width=30                 \
                                    icon=$YABAI_GRID              \
                                    icon.color=$ORANGE            \
                                    associated_display=active     \
           --subscribe system.yabai window_focus                  \
                                    windows_on_spaces             \
                                    mouse.clicked

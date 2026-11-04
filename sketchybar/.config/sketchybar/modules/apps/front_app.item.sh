#!/bin/bash

# Front App Module - Item Configuration
# Displays the currently focused application with icon


# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

sketchybar --add       item         front_app left                          \
           --set       front_app    script="$MODULE_DIR/apps/front_app.plugin.sh" \
                                    icon.font="sketchybar-app-font:Regular:16.0" \
                                    padding_left=2                          \
                                    padding_right=2                         \
                                    icon.padding_left=10                    \
                                    icon.padding_right=2                    \
                                    label.padding_right=12                  \
                                    label.color=$WHITE                      \
                                    label.font="$FONT:Bold:12.5"            \
                                    background.color=$BACKGROUND_1          \
                                    background.border_color=$BACKGROUND_2   \
                                    background.border_width=1               \
                                    background.drawing=on                   \
                                    associated_display=active               \
           --subscribe front_app    front_app_switched

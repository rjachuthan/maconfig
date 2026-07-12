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
                                    padding_left=4                          \
                                    label.color=$WHITE                      \
                                    label.font="$FONT:Black:12.0"           \
                                    associated_display=active               \
           --subscribe front_app    front_app_switched

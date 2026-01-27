#!/bin/bash

# Front App Module - Item Configuration
# Displays the currently focused application with icon

source "$CONFIG_DIR/config.sh"

sketchybar --add       item         front_app left                          \
           --set       front_app    script="$MODULE_DIR/apps/front_app.plugin.sh" \
                                    icon.font="sketchybar-app-font:Regular:16.0" \
                                    padding_left=0                          \
                                    label.color=$WHITE                      \
                                    label.font="$FONT:Black:12.0"           \
                                    associated_display=active               \
           --subscribe front_app    front_app_switched

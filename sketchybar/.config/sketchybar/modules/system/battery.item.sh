#!/bin/bash

# Battery Module - Item Configuration
# Displays battery status and percentage

source "$CONFIG_DIR/config.sh"

sketchybar --add item battery right                                   \
           --set battery script="$MODULE_DIR/system/battery.plugin.sh" \
                         icon.font="$FONT:Regular:19.0"               \
                         padding_right=5                              \
                         padding_left=0                               \
                         label.drawing=off                            \
                         update_freq=120                              \
                         updates=on                                   \
           --subscribe battery power_source_change system_woke

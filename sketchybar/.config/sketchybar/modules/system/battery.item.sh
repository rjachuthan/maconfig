#!/bin/bash

# Battery Module - Item Configuration
# Battery icon; bolt + percentage on AC power, percentage alone when low

sketchybar --add item battery right                                   \
           --set battery script="$MODULE_DIR/system/battery.plugin.sh" \
                         icon.font="$FONT:Regular:17.0"               \
                         icon.padding_left=0                          \
                         icon.padding_right=6                         \
                         label.font="$FONT:Semibold:12.0"             \
                         label.padding_left=0                         \
                         label.padding_right=6                        \
                         label.drawing=off                            \
                         padding_right=0                              \
                         padding_left=0                               \
                         update_freq=120                              \
                         updates=on                                   \
           --subscribe battery power_source_change system_woke

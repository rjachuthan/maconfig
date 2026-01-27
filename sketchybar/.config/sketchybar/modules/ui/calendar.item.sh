#!/bin/bash

# Calendar Module - Item Configuration
# Displays current date and time

source "$CONFIG_DIR/config.sh"

sketchybar --add item     calendar right                              \
           --set calendar icon=cal                                    \
                          icon.font="$FONT:Black:12.0"                \
                          icon.padding_right=0                        \
                          label.width=45                              \
                          label.align=right                           \
                          padding_left=15                             \
                          update_freq=30                              \
                          script="$MODULE_DIR/ui/calendar.plugin.sh"  \
                          click_script="$MODULE_DIR/ui/zen.plugin.sh" \
           --subscribe    calendar system_woke

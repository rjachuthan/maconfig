#!/bin/bash

source "$CONFIG_DIR/config.sh"

sketchybar --add event weather_update \
           --add item weather right \
           --set weather \
                 update_freq=900 \
                 script="$MODULE_DIR/integrations/weather.plugin.sh" \
                 click_script="$MODULE_DIR/integrations/weather.popup.sh" \
                 icon.font="$FONT:Regular:14.0" \
                 icon.padding_left=10 \
                 icon.padding_right=2 \
                 label.padding_left=2 \
                 label.padding_right=10 \
                 padding_left=0 \
                 padding_right=0 \
                 background.color="$BACKGROUND_1" \
                 background.border_color="$BACKGROUND_2" \
                 background.border_width=1 \
                 background.drawing=on \
                 popup.align=right \
                 popup.horizontal=on \
           --subscribe weather weather_update system_woke

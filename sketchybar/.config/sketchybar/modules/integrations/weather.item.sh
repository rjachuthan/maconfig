#!/bin/bash

source "$CONFIG_DIR/config.sh"

sketchybar --add event weather_update \
           --add item weather right \
           --set weather \
                 update_freq=900 \
                 script="$MODULE_DIR/integrations/weather.plugin.sh" \
                 click_script="$MODULE_DIR/integrations/weather.popup.sh" \
                 icon.font="$FONT:Regular:16.0" \
                 icon.padding_left=8 \
                 icon.padding_right=0 \
                 label.padding_left=4 \
                 label.padding_right=8 \
                 background.color="$BACKGROUND_1" \
                 background.corner_radius=6 \
                 background.height=24 \
                 popup.align=right \
                 popup.horizontal=on \
           --subscribe weather weather_update system_woke

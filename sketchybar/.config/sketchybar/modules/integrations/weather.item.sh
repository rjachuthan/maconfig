#!/bin/bash

# Weather Module - Item Configuration
# Current conditions; click for a forecast popup

sketchybar --add event weather_update \
           --add item weather right \
           --set weather "${pill[@]}" \
                 update_freq=900 \
                 script="$MODULE_DIR/integrations/weather.plugin.sh" \
                 click_script="$MODULE_DIR/integrations/weather.popup.sh" \
                 icon.font="$FONT:Regular:14.0" \
                 icon.padding_left=10 \
                 icon.padding_right=4 \
                 label.padding_left=2 \
                 label.padding_right=10 \
                 padding_left=0 \
                 padding_right=0 \
                 popup.align=right \
                 popup.horizontal=off \
                 popup.height=28 \
                 popup.y_offset=6 \
           --subscribe weather weather_update system_woke

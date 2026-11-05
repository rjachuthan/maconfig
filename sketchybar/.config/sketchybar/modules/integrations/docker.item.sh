#!/bin/bash

# Docker Module - Item Configuration
# Right-side pill: [docker logo] [running container count]. Hidden while the
# Docker daemon is not running. Click for a popup listing every running
# container with its published host ports; click a row with a port to open
# it in the browser, or the header to bring Docker Desktop to the front.

DOCKER_PLUGIN="$MODULE_DIR/integrations/docker.plugin.sh"

sketchybar --add event docker_update \
           --add item docker right \
           --set docker "${pill[@]}" \
                 drawing=off \
                 updates=on \
                 update_freq=5 \
                 script="$DOCKER_PLUGIN" \
                 click_script="$DOCKER_PLUGIN click" \
                 icon=":docker:" \
                 icon.font="sketchybar-app-font:Regular:15.0" \
                 icon.padding_left=10 \
                 icon.padding_right=4 \
                 label="0" \
                 label.font="$FONT:Bold:12.5" \
                 label.padding_left=2 \
                 label.padding_right=10 \
                 padding_left=0 \
                 padding_right=0 \
                 popup.align=right \
                 popup.horizontal=off \
                 popup.height=26 \
                 popup.y_offset=6 \
           --subscribe docker docker_update system_woke

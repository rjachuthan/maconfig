#!/bin/bash

# Aerospace Mode Module - Item Configuration
# Shows the current aerospace binding mode (dim in main, orange in service).
# Click to cycle through the modes.
# aerospace.toml fires the event from its on-mode-changed callback.

sketchybar --add event aerospace_mode_change \
           --add item aerospace.mode left \
           --set aerospace.mode "${pill[@]}" \
                 updates=on \
                 icon=􀆔 \
                 icon.font="$FONT:Bold:11.0" \
                 icon.color=$ORANGE \
                 icon.padding_left=10 \
                 icon.padding_right=4 \
                 label.font="$FONT:Heavy:10.0" \
                 label.color=$ORANGE \
                 label.padding_left=0 \
                 label.padding_right=10 \
                 padding_left=6 \
                 padding_right=0 \
                 script="$MODULE_DIR/workspace/mode.plugin.sh" \
           --subscribe aerospace.mode aerospace_mode_change mouse.clicked

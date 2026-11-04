#!/bin/bash

# Aerospace Workspace Module - Item Configuration
# Shows only the currently focused aerospace workspace.
# aerospace.toml fires the event from its exec-on-workspace-change callback.

sketchybar --add event aerospace_workspace_change \
           --add item aerospace.workspace left \
           --set aerospace.workspace "${pill[@]}" \
                 updates=on \
                 icon.drawing=off \
                 label.font="$FONT:Heavy:12.5" \
                 label.color=$WHITE \
                 label.width=26 \
                 label.align=center \
                 label.padding_left=0 \
                 label.padding_right=0 \
                 padding_left=0 \
                 padding_right=6 \
                 associated_display=active \
                 script="$MODULE_DIR/workspace/workspace.plugin.sh" \
                 click_script="aerospace workspace-back-and-forth" \
           --subscribe aerospace.workspace aerospace_workspace_change

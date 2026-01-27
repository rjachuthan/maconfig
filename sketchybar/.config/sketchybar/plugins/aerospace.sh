#!/bin/bash

# Load colors
source "$CONFIG_DIR/colors.sh"

# Check if this workspace is focused
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    # Active workspace - show with gradient accent background
    sketchybar --set "$NAME" \
        background.drawing=on \
        background.color=$ACCENT_COLOR \
        icon.color=0xff0f0f12
else
    # Inactive workspace
    sketchybar --set "$NAME" \
        background.drawing=off \
        background.color=$TRANSPARENT \
        icon.color=$TEXT_DIM
fi

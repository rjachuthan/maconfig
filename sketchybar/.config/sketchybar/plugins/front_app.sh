#!/bin/bash

# Source the generated icon map from sketchybar-app-font
source "$CONFIG_DIR/helpers/icon_map.sh"

if [ "$SENDER" = "front_app_switched" ]; then
    __icon_map "$INFO"
    sketchybar --set "$NAME" label="$INFO" icon="$icon_result"
fi

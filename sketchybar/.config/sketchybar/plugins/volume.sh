#!/bin/bash

if [ "$SENDER" = "volume_change" ]; then
    VOLUME="$INFO"

    case "$VOLUME" in
        [7-9][0-9]|100) ICON="󰕾" ;;
        [3-6][0-9])     ICON="󰖀" ;;
        [1-2][0-9])     ICON="󰕿" ;;
        [1-9])          ICON="󰕿" ;;
        0)              ICON="󰖁" ;;
        *)              ICON="󰕾" ;;
    esac

    sketchybar --set "$NAME" icon="$ICON"
fi

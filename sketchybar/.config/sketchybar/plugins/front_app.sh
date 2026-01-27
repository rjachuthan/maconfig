#!/bin/sh

if [ "$SENDER" = "front_app_switched" ]; then
  ICON=$($HOME/.config/sketchybar/plugins/icon_map.sh "$INFO")
  sketchybar --set $NAME label="$INFO" icon="$ICON"
fi

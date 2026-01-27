#!/bin/sh

if [ "$SENDER" = "front_app_switched" ]; then
  source "$HOME/.config/sketchybar/helpers/icon_map.sh"
  __icon_map "$INFO"
  sketchybar --set $NAME label="$INFO" icon="$icon_result"
fi

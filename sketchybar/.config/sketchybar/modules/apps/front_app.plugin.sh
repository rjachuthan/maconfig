#!/bin/bash

# Front App Module - Plugin
# Updates the front app display with icon from icon map. Apps the
# sketchybar-app-font has no glyph for can get a bundled PNG logo instead
# (drawn as the icon's background image).

source "$CONFIG_DIR/config.sh"

app_logo() {
  case "$1" in
    Herdr) echo "$CONFIG_DIR/assets/herdr.png" ;;
  esac
}

if [[ "$SENDER" == "front_app_switched" ]]; then
  logo="$(app_logo "$INFO")"
  if [[ -n "$logo" ]]; then
    # Paddings move off the icon so the image centres in its fixed width
    update_item "$NAME" label="$INFO" icon=" " \
      padding_left=10 icon.padding_left=0 icon.padding_right=0 icon.width=18 \
      label.padding_left=4 \
      icon.background.drawing=on icon.background.color=$TRANSPARENT \
      icon.background.image="$logo" icon.background.image.scale=0.1 \
      icon.background.image.corner_radius=4 icon.background.image.drawing=on
  else
    update_item "$NAME" label="$INFO" icon="$(get_app_icon "$INFO")" \
      padding_left=0 icon.padding_left=10 icon.padding_right=2 icon.width=dynamic \
      label.padding_left=0 \
      icon.background.drawing=off icon.background.image.drawing=off
  fi
fi

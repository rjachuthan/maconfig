#!/bin/bash

# Zen Mode Module - Plugin
# Toggles minimal display mode

source "$CONFIG_DIR/config.sh"

zen_on() {
  local args=(
    --set apple.logo drawing=off
    --set '/cpu.*/' drawing=off
    --set calendar icon.drawing=off
    --set system.yabai drawing=off
    --set separator drawing=off
    --set front_app drawing=off
    --set volume_icon drawing=off
    --set spotify.anchor drawing=off
    --set spotify.play updates=off
    --set brew drawing=off
  )
  batch_update "${args[@]}"
  save_state zen_mode on
}

zen_off() {
  local args=(
    --set apple.logo drawing=on
    --set '/cpu.*/' drawing=on
    --set calendar icon.drawing=on
    --set separator drawing=on
    --set front_app drawing=on
    --set system.yabai drawing=on
    --set volume_icon drawing=on
    --set spotify.play updates=on
    --set brew drawing=on
  )
  batch_update "${args[@]}"
  save_state zen_mode off
}

# Handle different invocation modes
if [[ "$1" == "on" ]]; then
  zen_on
elif [[ "$1" == "off" ]]; then
  zen_off
else
  # Toggle based on current state
  local current=$(query_item apple.logo "geometry.drawing")
  if [[ "$current" == "on" ]]; then
    zen_on
  else
    zen_off
  fi
fi

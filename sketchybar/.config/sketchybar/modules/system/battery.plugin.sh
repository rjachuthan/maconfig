#!/bin/bash

# Battery Module - Plugin
# Updates battery icon and color based on percentage and charging state

source "$CONFIG_DIR/config.sh"

update() {
  local percentage=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
  local charging=$(pmset -g batt | grep 'AC Power')

  # Exit if no battery info available
  [[ -z "$percentage" ]] && exit 0

  # Handle charging state
  if [[ -n "$charging" ]]; then
    update_item "$NAME" icon="$BATTERY_CHARGING" icon.color="$WHITE" drawing=on
    return 0
  fi

  # Select icon based on battery percentage
  local icon=$(select_icon_by_range "$percentage" \
    "0-9:$BATTERY_0" \
    "10-29:$BATTERY_25" \
    "30-59:$BATTERY_50" \
    "60-89:$BATTERY_75" \
    "90-100:$BATTERY_100")

  # Select color based on battery percentage
  local color=$(select_color_by_range "$percentage" \
    "0-29:$RED" \
    "30-59:$ORANGE" \
    "60-100:$WHITE")

  # Always show battery item
  update_item "$NAME" icon="$icon" icon.color="$color" drawing=on
}

update

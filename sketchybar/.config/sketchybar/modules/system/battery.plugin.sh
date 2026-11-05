#!/bin/bash

# Battery Module - Plugin
# Icon always reflects the real level. On AC power the label shows a bolt and
# the percentage (green while current flows in, white when plugged in but
# held/charged). On battery the label shows only below LOW_THRESHOLD.

source "$CONFIG_DIR/config.sh"

LOW_THRESHOLD=30

update() {
  local batt=$(pmset -g batt)
  local percentage=$(echo "$batt" | grep -Eo "\d+%" | cut -d% -f1)

  # No battery (desktop Mac)
  [[ -z "$percentage" ]] && exit 0

  # "AC attached" covers charging, charged and optimised-charging holds
  local plugged="" charging=""
  echo "$batt" | grep -q "AC Power" && plugged="yes"
  echo "$batt" | grep -q "; charging;" && charging="yes"

  local icon=$(select_icon_by_range "$percentage" \
    "0-9:$BATTERY_0" \
    "10-29:$BATTERY_25" \
    "30-59:$BATTERY_50" \
    "60-89:$BATTERY_75" \
    "90-100:$BATTERY_100")

  local color=$(select_color_by_range "$percentage" \
    "0-14:$RED" \
    "15-29:$ORANGE" \
    "30-100:$WHITE")

  local label="${percentage}%"
  local show_label="off"
  if [[ -n "$plugged" ]]; then
    label="$BATTERY_BOLT ${percentage}%"
    color="$WHITE"
    [[ -n "$charging" ]] && color="$GREEN"
    show_label="on"
  elif (( percentage < LOW_THRESHOLD )); then
    show_label="on"
  fi

  update_item "$NAME" icon="$icon" icon.color="$color" \
    label="$label" label.color="$color" label.drawing="$show_label"
}

update

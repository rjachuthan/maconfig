#!/bin/bash

# Battery Module - Plugin
# Icon reflects the level (or a bolt while actually charging). The percentage
# label shows only while charging or below LOW_THRESHOLD.

source "$CONFIG_DIR/config.sh"

LOW_THRESHOLD=30

update() {
  local batt=$(pmset -g batt)
  local percentage=$(echo "$batt" | grep -Eo "\d+%" | cut -d% -f1)

  # No battery (desktop Mac)
  [[ -z "$percentage" ]] && exit 0

  # "; charging;" only while current flows in; "charged" or
  # "AC attached; not charging" show the normal level icon instead
  local charging=""
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

  local show_label="off"
  if [[ -n "$charging" ]]; then
    icon="$BATTERY_CHARGING"
    color="$WHITE"
    show_label="on"
  elif (( percentage < LOW_THRESHOLD )); then
    show_label="on"
  fi

  update_item "$NAME" icon="$icon" icon.color="$color" \
    label="${percentage}%" label.color="$color" label.drawing="$show_label"
}

update

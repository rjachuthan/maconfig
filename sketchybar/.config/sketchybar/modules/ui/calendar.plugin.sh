#!/bin/bash

# Calendar Module - Plugin
# Updates date and time display


# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

update() {
  local date_str=$(date '+%a %d. %b')
  local uk_time=$(TZ="Europe/London" date '+%H:%M')
  local ist_time=$(TZ="Asia/Kolkata" date '+%H:%M')

  sketchybar --set "$NAME" label="$date_str" \
             --set clock.uk label="$uk_time" \
             --set clock.ist label="$ist_time"
}

update

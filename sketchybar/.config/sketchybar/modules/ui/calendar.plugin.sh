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
  # Local clock follows the detected location (system timezone), tagged with
  # its country code ("GB" is shown as "UK"). Falls back to "UK".
  local cc=$(load_state weather_last_location | jq -r '.country_code // empty' 2>/dev/null)
  cc=$(echo "${cc:-UK}" | tr '[:lower:]' '[:upper:]')
  [[ "$cc" == "GB" ]] && cc="UK"
  local local_time=$(date '+%H:%M')
  local ist_time=$(TZ="Asia/Kolkata" date '+%H:%M')

  sketchybar --set "$NAME" label="$date_str" \
             --set clock.uk icon="$cc" label="$local_time" \
             --set clock.ist label="$ist_time"
}

update

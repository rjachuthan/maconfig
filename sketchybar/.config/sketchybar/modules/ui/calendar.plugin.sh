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
  # Get UK time (Europe/London)
  local uk_time=$(TZ="Europe/London" date '+%H:%M')
  # Get IST time (Asia/Kolkata)
  local ist_time=$(TZ="Asia/Kolkata" date '+%H:%M')
  # Format: UK HH:MM | IST HH:MM
  local time_str="UK ${uk_time} | IST ${ist_time}"
  # Add subtle cyan color to time for visual distinction
  update_item "$NAME" icon="$date_str" icon.color="$WHITE" label="$time_str" label.color="$CYAN"
}

update

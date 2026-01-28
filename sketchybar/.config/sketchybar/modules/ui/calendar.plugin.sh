#!/bin/bash

# Calendar Module - Plugin
# Updates date and time display

source "$CONFIG_DIR/config.sh"

update() {
  local date_str=$(date '+%a %d. %b')
  local time_str=$(date '+%H:%M')
  # Add subtle cyan color to time for visual distinction
  update_item "$NAME" icon="$date_str" icon.color="$WHITE" label="$time_str" label.color="$CYAN"
}

update

#!/bin/bash

# Calendar Module - Plugin
# Updates date and time display

source "$CONFIG_DIR/config.sh"

update() {
  local date_str=$(date '+%a %d. %b')
  local time_str=$(date '+%H:%M')
  update_item "$NAME" icon="$date_str" label="$time_str"
}

update

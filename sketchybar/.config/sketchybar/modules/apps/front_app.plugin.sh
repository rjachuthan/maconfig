#!/bin/bash

# Front App Module - Plugin
# Updates the front app display with icon from icon map

source "$CONFIG_DIR/config.sh"

update() {
  if [[ "$SENDER" == "front_app_switched" ]]; then
    local icon=$(get_app_icon "$INFO")
    update_item "$NAME" label="$INFO" icon="$icon"
  fi
}

update

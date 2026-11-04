#!/bin/bash

# Front App Module - Plugin
# Updates the front app display with icon from icon map

source "$CONFIG_DIR/config.sh"

if [[ "$SENDER" == "front_app_switched" ]]; then
  update_item "$NAME" label="$INFO" icon="$(get_app_icon "$INFO")"
fi

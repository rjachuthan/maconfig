#!/bin/bash

# Zen Mode Module - Plugin
# Toggles minimal display mode

source "$CONFIG_DIR/config.sh"

# Handle different invocation modes
if [[ "$1" == "on" ]]; then
  enable_zen_mode
elif [[ "$1" == "off" ]]; then
  disable_zen_mode
else
  # Toggle based on current state
  toggle_zen_mode
fi

# Update space visibility after toggling zen mode
update_zen_spaces

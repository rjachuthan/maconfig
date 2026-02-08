#!/bin/bash

# Zen Spaces Module - Plugin
# Updates space visibility when in zen mode and workspace changes


# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

# Update space visibility based on zen mode state
update_zen_spaces


#!/bin/bash

# Zen Mode - toggles a minimal bar (focus pill + clock only)
# Usage: zen.plugin.sh [on|off]   (no argument toggles)

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/config.sh"

case "$1" in
  on)  enable_zen_mode ;;
  off) disable_zen_mode ;;
  *)   toggle_zen_mode ;;
esac

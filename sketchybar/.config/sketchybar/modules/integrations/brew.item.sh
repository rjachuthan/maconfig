#!/usr/bin/env bash

# Brew Module - Item Configuration
# Displays count of outdated Homebrew packages

# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

# Trigger the brew_update event when brew update or upgrade is run from cmdline
# e.g. via function in .zshrc

sketchybar --add event brew_update \
  --add item brew right \
  --set brew update_freq=300 \
  script="$MODULE_DIR/integrations/brew.plugin.sh" \
  icon=􀐛 \
  icon.color="$ORANGE" \
  label="?" \
  label.color="$ORANGE" \
  padding_right=10 \
  --subscribe brew brew_update

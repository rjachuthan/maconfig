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
  drawing=off \
  script="$MODULE_DIR/integrations/brew.plugin.sh" \
  icon=􀐛 \
  icon.color="$ORANGE" \
  label="?" \
  label.color="$ORANGE" \
  icon.padding_left=10 \
  icon.padding_right=2 \
  label.padding_right=10 \
  padding_left=4 \
  padding_right=0 \
  background.color="$BACKGROUND_1" \
  background.border_color="$BACKGROUND_2" \
  background.border_width=1 \
  background.drawing=on \
  --subscribe brew brew_update

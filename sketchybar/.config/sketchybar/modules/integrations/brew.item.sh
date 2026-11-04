#!/bin/bash

# Brew Module - Item Configuration
# Displays count of outdated Homebrew packages (hidden below a threshold).
# Trigger `sketchybar --trigger brew_update` after brew update/upgrade to refresh.

sketchybar --add event brew_update \
  --add item brew right \
  --set brew "${pill[@]}" \
  update_freq=3600 \
  drawing=off \
  script="$MODULE_DIR/integrations/brew.plugin.sh" \
  icon=􀐛 \
  icon.color="$ORANGE" \
  label="?" \
  label.color="$ORANGE" \
  icon.padding_left=10 \
  icon.padding_right=2 \
  label.padding_right=10 \
  padding_left=0 \
  padding_right=6 \
  --subscribe brew brew_update

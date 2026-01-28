#!/bin/bash

# Brew Module - Item Configuration
# Displays count of outdated Homebrew packages

source "$CONFIG_DIR/config.sh"

# Trigger the brew_update event when brew update or upgrade is run from cmdline
# e.g. via function in .zshrc

sketchybar --add event brew_update                              \
           --add item brew right                                \
           --set brew update_freq=1800                          \
                      script="$MODULE_DIR/integrations/brew.plugin.sh" \
                      icon=􀐛                                    \
                      icon.color=$ORANGE                        \
                      label=?                                   \
                      label.color=$ORANGE                       \
                      padding_right=10                          \
           --subscribe brew brew_update

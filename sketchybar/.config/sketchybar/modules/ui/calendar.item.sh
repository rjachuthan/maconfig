#!/bin/bash

# Calendar Module - Item Configuration
# Date plus two timezone clocks (UK / IST), grouped into one pill.
# Items are added right-to-left: clock.ist, clock.uk, then the date.

# Auto-detect CONFIG_DIR if not set (for IDE/shellcheck compatibility)
if [[ -z "$CONFIG_DIR" ]]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/config.sh"

clock_tag=(
  icon.font="$FONT:Heavy:8.5"
  icon.color=$GREY
  icon.padding_left=0
  icon.padding_right=5
  label.font="$FONT:Semibold:13.0"
  label.padding_left=0
  label.padding_right=0
  background.drawing=off
  click_script="$MODULE_DIR/ui/zen.plugin.sh"
)

sketchybar --add item     clock.ist right                             \
           --set clock.ist "${clock_tag[@]}"                          \
                          icon="IST"                                  \
                          label.color=$ORANGE                         \
                          padding_left=6                              \
                          padding_right=12                            \
                                                                      \
           --add item     clock.uk right                              \
           --set clock.uk "${clock_tag[@]}"                           \
                          icon="UK"                                   \
                          label.color=$CYAN                           \
                          padding_left=6                              \
                          padding_right=6                             \
                                                                      \
           --add item     calendar right                              \
           --set calendar icon.drawing=off                            \
                          label.font="$FONT:Bold:12.5"                \
                          label.color=$WHITE                          \
                          label.padding_left=12                       \
                          label.padding_right=6                       \
                          padding_left=0                              \
                          padding_right=0                             \
                          update_freq=30                              \
                          script="$MODULE_DIR/ui/calendar.plugin.sh"  \
                          click_script="$MODULE_DIR/ui/zen.plugin.sh" \
           --subscribe    calendar system_woke                        \
                                                                      \
           --add item     gap.clock right                             \
           --set gap.clock width=6 background.drawing=off icon.drawing=off label.drawing=off padding_left=0 padding_right=0 \
                                                                      \
           --add bracket  clock calendar clock.uk clock.ist           \
           --set clock    background.color=$BACKGROUND_1              \
                          background.border_color=$BACKGROUND_2      \
                          background.border_width=1                   \
                          background.corner_radius=$BACKGROUND_CORNER_RADIUS \
                          background.height=$BACKGROUND_HEIGHT        \
                          background.drawing=on

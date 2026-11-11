#!/bin/bash

# Herdr Module - Item Configuration
# Right-side pill summarising herdr agents that need attention, across both
# the herdr TUI and the Herdr desktop app:
#   ◐ working   ⚠ blocked (waiting on approval/question)   ✓ done (not yet seen)
# Idle agents (finished and already viewed) are not counted; with nothing
# active only the herdr logo shows. Click for a popup listing every agent
# (idle ones too), grouped by TUI / Desktop, with its CLI logo from
# assets/agents/; click a row to jump to it in the app it runs in (which
# marks it seen).
#
# Right-side items are laid out right-to-left, so they are added in reverse:
# done, blocked, working, then the herdr logo.

HERDR_PLUGIN="$MODULE_DIR/integrations/herdr.plugin.sh"

count_style=(
  drawing=off
  icon.font="$FONT:Bold:12.0"
  icon.padding_left=4
  icon.padding_right=3
  label.font="$FONT:Bold:12.5"
  label.padding_left=0
  label.padding_right=4
  padding_left=0
  padding_right=0
  click_script="$HERDR_PLUGIN click"
)

sketchybar --add event herdr_update \
                                                       \
           --add item herdr.done right \
           --set herdr.done "${count_style[@]}" icon="$AGENT_DONE" \
                 icon.color=$GREEN label.color=$GREEN \
                                                       \
           --add item herdr.blocked right \
           --set herdr.blocked "${count_style[@]}" icon="$AGENT_BLOCKED" \
                 icon.color=$ORANGE label.color=$ORANGE \
                                                       \
           --add item herdr.working right \
           --set herdr.working "${count_style[@]}" icon="$AGENT_WORKING" \
                 icon.color=$WHITE label.color=$WHITE \
                                                       \
           --add item herdr right \
           --set herdr updates=on \
                 update_freq=2 \
                 script="$HERDR_PLUGIN" \
                 click_script="$HERDR_PLUGIN click" \
                 icon.drawing=off \
                 label.drawing=off \
                 background.image="$CONFIG_DIR/assets/herdr.png" \
                 background.image.scale=0.11 \
                 background.image.corner_radius=4 \
                 background.image.drawing=on \
                 background.drawing=on \
                 background.color=$TRANSPARENT \
                 width=24 \
                 padding_left=8 \
                 padding_right=0 \
                 popup.align=left \
                 popup.horizontal=off \
                 popup.height=26 \
                 popup.y_offset=6 \
           --subscribe herdr herdr_update system_woke \
                                                       \
           --add bracket herdr.pill herdr herdr.working herdr.blocked herdr.done \
           --set herdr.pill "${pill[@]}"

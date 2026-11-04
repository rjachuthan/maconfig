#!/bin/bash

# Aerospace Mode Module - Plugin
# Always shows the current binding mode: dim grey in main, orange otherwise.
# Clicking cycles to the next mode defined in aerospace.toml.

source "$CONFIG_DIR/config.sh"

current_mode() {
  local mode=$(aerospace list-modes --current 2>/dev/null)
  echo "${mode:-main}"
}

# Switch to the mode after the current one (wrapping around).
# aerospace's on-mode-changed callback then triggers the redraw.
cycle_mode() {
  local current=$(current_mode)
  local modes=($(aerospace list-modes 2>/dev/null))
  (( ${#modes[@]} > 1 )) || return
  local i next="${modes[0]}"
  for i in "${!modes[@]}"; do
    if [[ "${modes[$i]}" == "$current" ]]; then
      next="${modes[$(( (i + 1) % ${#modes[@]} ))]}"
      break
    fi
  done
  aerospace mode "$next"
}

update() {
  local mode=$(current_mode)
  local color=$GREY
  [[ "$mode" != "main" ]] && color=$ORANGE

  sketchybar --set "$NAME" \
    label="$(echo "$mode" | tr '[:lower:]' '[:upper:]')" \
    icon.color="$color" \
    label.color="$color"
}

case "$SENDER" in
  "mouse.clicked") cycle_mode ;;
  *) update ;;
esac

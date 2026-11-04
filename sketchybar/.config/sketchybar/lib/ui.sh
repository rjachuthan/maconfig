#!/bin/bash

# Sketchybar library: visibility and slider helpers

show_item() { sketchybar --set "$1" drawing=on; }
hide_item() { sketchybar --set "$1" drawing=off; }

# Usage: animate_item tanh 30 volume slider.width=100
animate_item() {
  local curve="$1" duration="$2" item="$3"
  shift 3
  sketchybar --animate "$curve" "$duration" --set "$item" "$@"
}

# Usage: update_slider ITEM PERCENTAGE [WIDTH]
update_slider() {
  sketchybar --set "$1" slider.percentage="$2" \
             --animate tanh 30 --set "$1" slider.width="${3:-100}"
}

reset_slider() { sketchybar --animate tanh 30 --set "$1" slider.width=0; }
show_slider_knob() { sketchybar --set "$1" slider.knob.drawing=on; }
hide_slider_knob() { sketchybar --set "$1" slider.knob.drawing=off; }

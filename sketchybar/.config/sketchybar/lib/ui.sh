#!/bin/bash

# Sketchybar Library - UI Rendering
# Functions for visual updates and rendering

# ============================================================================
# Item Visibility Functions
# ============================================================================

# Show an item
# Usage: show_item ITEM_NAME
show_item() {
  local item="$1"
  sketchybar --set "$item" drawing=on
}

# Hide an item
# Usage: hide_item ITEM_NAME
hide_item() {
  local item="$1"
  sketchybar --set "$item" drawing=off
}

# Toggle item visibility
# Usage: toggle_item ITEM_NAME
toggle_item() {
  local item="$1"
  local current=$(query_item "$item" drawing)
  local new_state=$([[ "$current" == "on" ]] && echo "off" || echo "on")
  sketchybar --set "$item" drawing="$new_state"
}

# Show multiple items
# Usage: show_items ITEM1 ITEM2 ITEM3 ...
show_items() {
  local args=()
  for item in "$@"; do
    args+=(--set "$item" drawing=on)
  done
  batch_update "${args[@]}"
}

# Hide multiple items
# Usage: hide_items ITEM1 ITEM2 ITEM3 ...
hide_items() {
  local args=()
  for item in "$@"; do
    args+=(--set "$item" drawing=off)
  done
  batch_update "${args[@]}"
}

# ============================================================================
# Color and Style Functions
# ============================================================================

# Set item color
# Usage: set_color ITEM_NAME COLOR
set_color() {
  local item="$1"
  local color="$2"
  sketchybar --set "$item" icon.color="$color" label.color="$color"
}

# Set icon only
# Usage: set_icon ITEM_NAME ICON [COLOR]
set_icon() {
  local item="$1"
  local icon="$2"
  local color="${3:-}"

  if [[ -n "$color" ]]; then
    sketchybar --set "$item" icon="$icon" icon.color="$color"
  else
    sketchybar --set "$item" icon="$icon"
  fi
}

# Set label only
# Usage: set_label ITEM_NAME LABEL [COLOR]
set_label() {
  local item="$1"
  local label="$2"
  local color="${3:-}"

  if [[ -n "$color" ]]; then
    sketchybar --set "$item" label="$label" label.color="$color"
  else
    sketchybar --set "$item" label="$label"
  fi
}

# Set background color
# Usage: set_background ITEM_NAME COLOR
set_background() {
  local item="$1"
  local color="$2"
  sketchybar --set "$item" background.color="$color"
}

# Highlight item (set icon/label highlight)
# Usage: highlight_item ITEM_NAME [on|off]
highlight_item() {
  local item="$1"
  local state="${2:-on}"
  sketchybar --set "$item" icon.highlight="$state" label.highlight="$state"
}

# ============================================================================
# Animation Functions
# ============================================================================

# Animate item property change
# Usage: animate_item CURVE DURATION ITEM_NAME PROPERTIES...
# Example: animate_item tanh 30 volume slider.width=100
animate_item() {
  local curve="$1"
  local duration="$2"
  local item="$3"
  shift 3

  sketchybar --animate "$curve" "$duration" --set "$item" "$@"
}

# Fade in item
# Usage: fade_in ITEM_NAME [DURATION]
fade_in() {
  local item="$1"
  local duration="${2:-30}"
  sketchybar --set "$item" drawing=off
  sketchybar --animate tanh "$duration" --set "$item" drawing=on
}

# Fade out item
# Usage: fade_out ITEM_NAME [DURATION]
fade_out() {
  local item="$1"
  local duration="${2:-30}"
  sketchybar --animate tanh "$duration" --set "$item" drawing=off
}

# ============================================================================
# Slider Functions
# ============================================================================

# Update slider percentage
# Usage: update_slider ITEM_NAME PERCENTAGE [WIDTH]
update_slider() {
  local item="$1"
  local percentage="$2"
  local width="${3:-100}"

  sketchybar --set "$item" slider.percentage="$percentage" \
             --animate tanh 30 --set "$item" slider.width="$width"
}

# Reset slider
# Usage: reset_slider ITEM_NAME
reset_slider() {
  local item="$1"
  sketchybar --animate tanh 30 --set "$item" slider.width=0
}

# Show slider knob
# Usage: show_slider_knob ITEM_NAME
show_slider_knob() {
  local item="$1"
  sketchybar --set "$item" slider.knob.drawing=on
}

# Hide slider knob
# Usage: hide_slider_knob ITEM_NAME
hide_slider_knob() {
  local item="$1"
  sketchybar --set "$item" slider.knob.drawing=off
}

# ============================================================================
# Progress Indicator Functions
# ============================================================================

# Show loading indicator
# Usage: show_loading ITEM_NAME
show_loading() {
  local item="$1"
  sketchybar --set "$item" icon="$LOADING" icon.color="$GREY"
}

# Update progress (for items with a progress bar)
# Usage: update_progress ITEM_NAME CURRENT TOTAL
update_progress() {
  local item="$1"
  local current="$2"
  local total="$3"
  local percentage=$(safe_divide $((current * 100)) "$total" 0)

  sketchybar --set "$item" label="${current}/${total}" \
                          background.color="$BACKGROUND_1" \
                          background.height="$BACKGROUND_HEIGHT" \
                          background.padding_left=$((percentage / 10))
}

# ============================================================================
# State Indicator Functions
# ============================================================================

# Show success state
# Usage: show_success ITEM_NAME [MESSAGE]
show_success() {
  local item="$1"
  local message="${2:-}"

  if [[ -n "$message" ]]; then
    sketchybar --set "$item" icon="✓" icon.color="$GREEN" label="$message"
  else
    sketchybar --set "$item" icon.color="$GREEN"
  fi
}

# Show error state
# Usage: show_error ITEM_NAME [MESSAGE]
show_error() {
  local item="$1"
  local message="${2:-}"

  if [[ -n "$message" ]]; then
    sketchybar --set "$item" icon="✗" icon.color="$RED" label="$message"
  else
    sketchybar --set "$item" icon.color="$RED"
  fi
}

# Show warning state
# Usage: show_warning ITEM_NAME [MESSAGE]
show_warning() {
  local item="$1"
  local message="${2:-}"

  if [[ -n "$message" ]]; then
    sketchybar --set "$item" icon="⚠" icon.color="$ORANGE" label="$message"
  else
    sketchybar --set "$item" icon.color="$ORANGE"
  fi
}

# Reset to default state
# Usage: reset_state ITEM_NAME
reset_state() {
  local item="$1"
  sketchybar --set "$item" icon.color="$WHITE" label.color="$WHITE"
}

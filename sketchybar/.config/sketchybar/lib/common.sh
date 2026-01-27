#!/bin/bash

# Sketchybar Library - Common Utilities
# Core functions to eliminate duplication across modules

# ============================================================================
# Range-Based Selection Functions
# ============================================================================

# Select icon based on value ranges
# Usage: select_icon_by_range VALUE "MIN-MAX:ICON" "MIN-MAX:ICON" ...
# Example: select_icon_by_range 75 "0-29:$ICON_LOW" "30-69:$ICON_MED" "70-100:$ICON_HIGH"
select_icon_by_range() {
  local value=$1
  shift

  for range_spec in "$@"; do
    local range="${range_spec%%:*}"
    local icon="${range_spec#*:}"
    local min="${range%-*}"
    local max="${range#*-}"

    if [[ $value -ge $min && $value -le $max ]]; then
      echo "$icon"
      return 0
    fi
  done

  # Default to last icon if no match
  echo "${icon}"
}

# Select color based on value ranges
# Usage: select_color_by_range VALUE "MIN-MAX:COLOR" "MIN-MAX:COLOR" ...
# Example: select_color_by_range 15 "0-29:$RED" "30-69:$ORANGE" "70-100:$GREEN"
select_color_by_range() {
  local value=$1
  shift

  for range_spec in "$@"; do
    local range="${range_spec%%:*}"
    local color="${range_spec#*:}"
    local min="${range%-*}"
    local max="${range#*-}"

    if [[ $value -ge $min && $value -le $max ]]; then
      echo "$color"
      return 0
    fi
  done

  # Default to last color if no match
  echo "${color}"
}

# Select any value based on ranges (generic version)
# Usage: select_by_range VALUE "MIN-MAX:VALUE" "MIN-MAX:VALUE" ...
select_by_range() {
  local value=$1
  shift

  for range_spec in "$@"; do
    local range="${range_spec%%:*}"
    local result="${range_spec#*:}"
    local min="${range%-*}"
    local max="${range#*-}"

    if [[ $value -ge $min && $value -le $max ]]; then
      echo "$result"
      return 0
    fi
  done

  # Default to last value if no match
  echo "${result}"
}

# ============================================================================
# Item Update Functions
# ============================================================================

# Update a sketchybar item with multiple properties
# Usage: update_item ITEM_NAME key=value key=value ...
# Example: update_item battery icon="$ICON" icon.color="$RED" drawing=on
update_item() {
  local item_name="$1"
  shift
  sketchybar --set "$item_name" "$@"
}

# Batch update multiple items
# Usage: batch_update --set item1 prop=val --set item2 prop=val
# Returns: 0 on success
batch_update() {
  sketchybar -m "$@"
}

# Build arguments array for batch updates
# Usage:
#   args=()
#   add_args args --set item1 prop=val
#   add_args args --set item2 prop=val
#   batch_update "${args[@]}"
add_args() {
  local -n arr=$1
  shift
  arr+=("$@")
}

# ============================================================================
# Boolean Toggle Functions
# ============================================================================

# Toggle a boolean property (on/off or true/false)
# Usage: toggle_boolean ITEM_NAME PROPERTY CURRENT_VALUE
# Example: toggle_boolean spotify.shuffle icon.highlight true
# Returns: The new value (on/off or true/false depending on input)
toggle_boolean() {
  local item="$1"
  local property="$2"
  local current="$3"
  local new_value

  if [[ "$current" == "true" || "$current" == "on" ]]; then
    new_value="off"
    [[ "$current" == "true" ]] && new_value="false"
  else
    new_value="on"
    [[ "$current" == "false" ]] && new_value="true"
  fi

  sketchybar --set "$item" "$property=$new_value"
  echo "$new_value"
}

# Get boolean value (normalize to on/off)
normalize_boolean() {
  local value="$1"
  if [[ "$value" == "true" || "$value" == "on" || "$value" == "1" ]]; then
    echo "on"
  else
    echo "off"
  fi
}

# ============================================================================
# Popup Management Functions
# ============================================================================

# Toggle popup drawing state
# Usage: toggle_popup ANCHOR_ITEM [STATE]
# Example: toggle_popup spotify.anchor on
render_popup() {
  local anchor="$1"
  local state="${2:-toggle}"

  if [[ "$state" == "toggle" ]]; then
    # Query current state and toggle
    local current=$(sketchybar --query "$anchor" | jq -r '.popup.drawing')
    state=$([[ "$current" == "on" ]] && echo "off" || echo "on")
  fi

  sketchybar --set "$anchor" popup.drawing="$state"
}

# ============================================================================
# Event Dispatching Functions
# ============================================================================

# Standard event dispatcher using associative array
# Usage:
#   declare -A handlers=(
#     ["mouse.clicked"]="handle_click"
#     ["volume_change"]="handle_volume"
#   )
#   dispatch_event "$SENDER" handlers
dispatch_event() {
  local sender="$1"
  local -n handler_map=$2

  if [[ -n "${handler_map[$sender]}" ]]; then
    "${handler_map[$sender]}"
  elif [[ -n "${handler_map[*]}" ]]; then
    # Call default handler if exists
    "${handler_map[*]}" 2>/dev/null || true
  fi
}

# Simple case-based dispatcher (for compatibility)
# Usage: dispatch_case "$SENDER" update mouse.clicked:handle_click mouse.entered:handle_enter
dispatch_case() {
  local sender="$1"
  local default_handler="$2"
  shift 2

  for mapping in "$@"; do
    local event="${mapping%%:*}"
    local handler="${mapping#*:}"
    if [[ "$sender" == "$event" ]]; then
      "$handler"
      return 0
    fi
  done

  # Call default handler if no match
  [[ -n "$default_handler" ]] && "$default_handler"
}

# ============================================================================
# Query Functions
# ============================================================================

# Get a property value from a sketchybar item
# Usage: query_item ITEM_NAME PROPERTY
# Example: query_item battery icon.color
query_item() {
  local item="$1"
  local property="$2"
  sketchybar --query "$item" | jq -r ".$property"
}

# Check if item exists
# Usage: item_exists ITEM_NAME
item_exists() {
  local item="$1"
  sketchybar --query "$item" &>/dev/null
}

# ============================================================================
# String Manipulation Functions
# ============================================================================

# Truncate string with ellipsis
# Usage: truncate_string STRING MAX_LENGTH
# Example: truncate_string "Very Long Song Title" 20
truncate_string() {
  local string="$1"
  local max_length="$2"

  if [[ ${#string} -gt $max_length ]]; then
    echo "${string:0:$max_length}..."
  else
    echo "$string"
  fi
}

# ============================================================================
# Validation Functions
# ============================================================================

# Check if a value is a number
is_number() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

# Check if a value is empty or null
is_empty() {
  [[ -z "$1" || "$1" == "null" ]]
}

# Safe division (avoids divide by zero)
safe_divide() {
  local numerator=$1
  local denominator=$2
  local default=${3:-0}

  if [[ $denominator -eq 0 ]]; then
    echo "$default"
  else
    echo $((numerator / denominator))
  fi
}

# ============================================================================
# Debug Functions
# ============================================================================

# Log debug message (only if DEBUG is set)
debug_log() {
  [[ -n "$DEBUG" ]] && echo "[DEBUG] $*" >&2
}

# Log error message
error_log() {
  echo "[ERROR] $*" >&2
}

# Log info message
info_log() {
  echo "[INFO] $*" >&2
}

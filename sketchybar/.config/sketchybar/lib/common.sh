#!/bin/bash

# Sketchybar library: small helpers shared by the plugins

# Pick a value from "MIN-MAX:VALUE" (or "N:VALUE") ranges.
# Falls back to the last value when nothing matches.
# Usage: select_by_range 75 "0-29:$LOW" "30-69:$MID" "70-100:$HIGH"
select_by_range() {
  local value=$1
  shift
  local spec range result min max
  for spec in "$@"; do
    range="${spec%%:*}"
    result="${spec#*:}"
    # Bounds may be negative, e.g. "-999--10"
    [[ "$range" =~ ^(-?[0-9]+)(-(-?[0-9]+))?$ ]] || continue
    min="${BASH_REMATCH[1]}"
    max="${BASH_REMATCH[3]:-$min}"
    if [[ $value -ge $min && $value -le $max ]]; then
      echo "$result"
      return 0
    fi
  done
  echo "$result"
}

# Readable aliases used by the plugins
select_icon_by_range() { select_by_range "$@"; }
select_color_by_range() { select_by_range "$@"; }

# Set properties on an item
# Usage: update_item battery icon="$ICON" icon.color="$RED"
update_item() {
  local item_name="$1"
  shift
  sketchybar --set "$item_name" "$@"
}

# Read a property from an item
# Usage: query_item volume slider.width
query_item() {
  sketchybar --query "$1" | jq -r ".$2"
}

# Trigger a custom sketchybar event
trigger_event() {
  sketchybar --trigger "$1"
}

# App icon from sketchybar-app-font's generated icon map
# Usage: get_app_icon "Google Chrome"
if [[ -f "$HELPERS_DIR/icon_map.sh" ]]; then
  source "$HELPERS_DIR/icon_map.sh"
fi

get_app_icon() {
  if ! declare -f __icon_map >/dev/null 2>&1; then
    echo ":default:"
    return 1
  fi
  __icon_map "$1"
  echo "$icon_result"
}

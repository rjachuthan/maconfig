#!/bin/bash

# Yabai Module - Plugin
# Manages window state and workspace icons (aerospace/yabai compatible)

source "$CONFIG_DIR/config.sh"

# Show window state indicators
window_state() {
  # Try to get window info from aerospace first, fall back to yabai
  if command -v aerospace &> /dev/null; then
    # Aerospace-based window state
    local focused=$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)

    local args=()
    if [[ -n "$focused" ]]; then
      args+=(--set "$NAME" icon="$YABAI_GRID" icon.color="$ORANGE" label.drawing=off)
    else
      args+=(--set "$NAME" icon="$YABAI_GRID" icon.color="$GREY" label.drawing=off)
    fi

    batch_update "${args[@]}"

  elif command -v yabai &> /dev/null; then
    # Original yabai-based window state
    local window=$(yabai -m query --windows --window 2>/dev/null)

    if [[ -z "$window" ]]; then
      update_item "$NAME" icon="$YABAI_GRID" icon.color="$GREY" label.drawing=off
      return
    fi

    local current=$(echo "$window" | jq '.["stack-index"]')
    local args=()

    if [[ $current -gt 0 ]]; then
      local last=$(yabai -m query --windows --window stack.last | jq '.["stack-index"]')
      args+=(--set "$NAME" icon="$YABAI_STACK" icon.color="$RED" label.drawing=on label="[$current/$last]")
    else
      args+=(--set "$NAME" label.drawing=off)
      local is_floating=$(echo "$window" | jq '.["is-floating"]')

      if [[ "$is_floating" == "false" ]]; then
        if [[ "$(echo "$window" | jq '.["has-fullscreen-zoom"]')" == "true" ]]; then
          args+=(--set "$NAME" icon="$YABAI_FULLSCREEN_ZOOM" icon.color="$GREEN")
        elif [[ "$(echo "$window" | jq '.["has-parent-zoom"]')" == "true" ]]; then
          args+=(--set "$NAME" icon="$YABAI_PARENT_ZOOM" icon.color="$BLUE")
        else
          args+=(--set "$NAME" icon="$YABAI_GRID" icon.color="$ORANGE")
        fi
      else
        args+=(--set "$NAME" icon="$YABAI_FLOAT" icon.color="$MAGENTA")
      fi
    fi

    batch_update "${args[@]}"
  else
    # No window manager found, show default icon
    update_item "$NAME" icon="$YABAI_GRID" icon.color="$GREY" label.drawing=off
  fi
}

# Update workspace icons with app icons
windows_on_spaces() {
  if command -v aerospace &> /dev/null; then
    # Aerospace-based window listing
    local args=()
    for space in $(aerospace list-workspaces --all 2>/dev/null); do
      local icon_strip=" "
      local apps=$(aerospace list-windows --workspace "$space" --format '%{app-name}' 2>/dev/null)

      if [[ -n "$apps" ]]; then
        while IFS= read -r app; do
          local icon=$(get_app_icon "$app")
          icon_strip+=" $icon"
        done <<< "$apps"
      fi

      args+=(--set "space.$space" label="$icon_strip" label.drawing=on)
    done
    batch_update "${args[@]}" 2>/dev/null

  elif command -v yabai &> /dev/null; then
    # Original yabai-based window listing
    local current_spaces="$(yabai -m query --displays | jq -r '.[].spaces | @sh')"
    local args=()

    while read -r line; do
      for space in $line; do
        local icon_strip=" "
        local apps=$(yabai -m query --windows --space "$space" | jq -r ".[].app")

        if [[ -n "$apps" ]]; then
          while IFS= read -r app; do
            local icon=$(get_app_icon "$app")
            icon_strip+=" $icon"
          done <<< "$apps"
        fi

        args+=(--set "space.$space" label="$icon_strip" label.drawing=on)
      done
    done <<< "$current_spaces"

    batch_update "${args[@]}"
  fi
}

# Toggle float on click
mouse_clicked() {
  if command -v yabai &> /dev/null; then
    yabai -m window --toggle float
  fi
  window_state
}

# Dispatch events
case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  "forced") exit 0 ;;
  "window_focus") window_state ;;
  "windows_on_spaces"|"aerospace_workspace_change") windows_on_spaces ;;
esac

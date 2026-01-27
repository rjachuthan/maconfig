#!/bin/sh

# This script works with both yabai and aerospace
# It shows window state indicators

window_state() {
  source "$HOME/.config/sketchybar/colors.sh"
  source "$HOME/.config/sketchybar/icons.sh"

  # Try to get window info from aerospace first, fall back to yabai
  if command -v aerospace &> /dev/null; then
    # Aerospace-based window state
    FOCUSED=$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)

    args=()
    if [ -n "$FOCUSED" ]; then
      args+=(--set $NAME icon=$YABAI_GRID icon.color=$ORANGE label.drawing=off)
    else
      args+=(--set $NAME icon=$YABAI_GRID icon.color=$GREY label.drawing=off)
    fi

    sketchybar -m "${args[@]}"
  elif command -v yabai &> /dev/null; then
    # Original yabai-based window state
    WINDOW=$(yabai -m query --windows --window 2>/dev/null)
    if [ -z "$WINDOW" ]; then
      sketchybar --set $NAME icon=$YABAI_GRID icon.color=$GREY label.drawing=off
      return
    fi

    CURRENT=$(echo "$WINDOW" | jq '.["stack-index"]')

    args=()
    if [[ $CURRENT -gt 0 ]]; then
      LAST=$(yabai -m query --windows --window stack.last | jq '.["stack-index"]')
      args+=(--set $NAME icon=$YABAI_STACK icon.color=$RED label.drawing=on label=$(printf "[%s/%s]" "$CURRENT" "$LAST"))
    else
      args+=(--set $NAME label.drawing=off)
      case "$(echo "$WINDOW" | jq '.["is-floating"]')" in
        "false")
          if [ "$(echo "$WINDOW" | jq '.["has-fullscreen-zoom"]')" = "true" ]; then
            args+=(--set $NAME icon=$YABAI_FULLSCREEN_ZOOM icon.color=$GREEN)
          elif [ "$(echo "$WINDOW" | jq '.["has-parent-zoom"]')" = "true" ]; then
            args+=(--set $NAME icon=$YABAI_PARENT_ZOOM icon.color=$BLUE)
          else
            args+=(--set $NAME icon=$YABAI_GRID icon.color=$ORANGE)
          fi
          ;;
        "true")
          args+=(--set $NAME icon=$YABAI_FLOAT icon.color=$MAGENTA)
          ;;
      esac
    fi

    sketchybar -m "${args[@]}"
  else
    # No window manager found, show default icon
    sketchybar --set $NAME icon=$YABAI_GRID icon.color=$GREY label.drawing=off
  fi
}

windows_on_spaces () {
  source "$HOME/.config/sketchybar/helpers/icon_map.sh"
  if command -v aerospace &> /dev/null; then
    # Aerospace-based window listing
    args=()
    for space in $(aerospace list-workspaces --all 2>/dev/null); do
      icon_strip=" "
      apps=$(aerospace list-windows --workspace $space --format '%{app-name}' 2>/dev/null)
      if [ "$apps" != "" ]; then
        while IFS= read -r app; do
          __icon_map "$app"
          icon_strip+=" $icon_result"
        done <<< "$apps"
      fi
      args+=(--set space.$space label="$icon_strip" label.drawing=on)
    done
    sketchybar -m "${args[@]}" 2>/dev/null
  elif command -v yabai &> /dev/null; then
    # Original yabai-based window listing
    CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces | @sh')"

    args=()
    while read -r line
    do
      for space in $line
      do
        icon_strip=" "
        apps=$(yabai -m query --windows --space $space | jq -r ".[].app")
        if [ "$apps" != "" ]; then
          while IFS= read -r app; do
            __icon_map "$app"
            icon_strip+=" $icon_result"
          done <<< "$apps"
        fi
        args+=(--set space.$space label="$icon_strip" label.drawing=on)
      done
    done <<< "$CURRENT_SPACES"

    sketchybar -m "${args[@]}"
  fi
}

mouse_clicked() {
  if command -v yabai &> /dev/null; then
    yabai -m window --toggle float
  fi
  window_state
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "forced") exit 0
  ;;
  "window_focus") window_state
  ;;
  "windows_on_spaces"|"aerospace_workspace_change") windows_on_spaces
  ;;
esac

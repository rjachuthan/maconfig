#!/bin/bash

# Volume Module - Plugin
# Updates volume icon and handles slider/device switching

source "$CONFIG_DIR/config.sh"

WIDTH=100

# Update volume icon based on current level
volume_change() {
  local icon=$(select_icon_by_range "$INFO" \
    "0:$VOLUME_0" \
    "1-9:$VOLUME_10" \
    "10-33:$VOLUME_33" \
    "34-66:$VOLUME_66" \
    "67-100:$VOLUME_100")

  update_item volume_icon label="$icon"
  update_slider volume "$INFO" "$WIDTH"

  sleep 2

  # Check if volume was changed again while sleeping
  local final_percentage=$(query_item "$NAME" "slider.percentage")
  if [[ "$final_percentage" == "$INFO" ]]; then
    reset_slider "$NAME"
  fi
}

# Handle slider click (set volume)
mouse_clicked() {
  if [[ "$NAME" == "volume" ]]; then
    osascript -e "set volume output volume $PERCENTAGE"
  elif [[ "$NAME" == "volume_icon" ]]; then
    # Toggle detail or show device switcher
    if [[ "$BUTTON" == "right" || "$MODIFIER" == "shift" ]]; then
      toggle_devices
    else
      toggle_detail
    fi
  fi
}

# Show/hide volume slider
toggle_detail() {
  local initial_width=$(query_item volume "slider.width")
  if [[ "$initial_width" == "0" ]]; then
    animate_item tanh 30 volume slider.width="$WIDTH"
  else
    reset_slider volume
  fi
}

# Toggle audio device popup
toggle_devices() {
  which SwitchAudioSource >/dev/null || exit 0

  local args=(--remove '/volume.device\.*/' --set "$NAME" popup.drawing=toggle)
  local counter=0
  local current="$(SwitchAudioSource -t output -c)"

  while IFS= read -r device; do
    local color=$GREY
    [[ "$device" == "$current" ]] && color=$WHITE

    args+=(--add item volume.device.$counter popup."$NAME"
           --set volume.device.$counter label="$device"
                                        label.color="$color"
                 click_script="SwitchAudioSource -s \"$device\" && sketchybar --set /volume.device\.*/ label.color=$GREY --set \$NAME label.color=$WHITE --set $NAME popup.drawing=off")
    ((counter++))
  done <<< "$(SwitchAudioSource -a -t output)"

  batch_update "${args[@]}" > /dev/null
}

# Show slider knob on hover
mouse_entered() {
  show_slider_knob "$NAME"
}

# Hide slider knob when not hovering
mouse_exited() {
  hide_slider_knob "$NAME"
}

# Dispatch events
case "$SENDER" in
  "volume_change") volume_change ;;
  "mouse.clicked") mouse_clicked ;;
  "mouse.entered") mouse_entered ;;
  "mouse.exited") mouse_exited ;;
esac

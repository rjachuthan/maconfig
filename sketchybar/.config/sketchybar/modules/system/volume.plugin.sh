#!/bin/bash

# Volume Module - Plugin
# Updates the volume icon and handles the slider

source "$CONFIG_DIR/config.sh"

WIDTH=100

# Update volume icon based on current level
volume_change() {
  local icon=$(select_icon_by_range "$INFO" \
    "0-0:$VOLUME_0" \
    "1-9:$VOLUME_10" \
    "10-33:$VOLUME_33" \
    "34-66:$VOLUME_66" \
    "67-100:$VOLUME_100")

  # Muted is dimmed; any other level is plain white
  local color=$WHITE
  [[ "$INFO" == "0" ]] && color=$GREY

  update_item volume_icon label="$icon" label.color="$color"
  update_slider volume "$INFO" "$WIDTH"

  sleep 2

  # Collapse the slider unless the volume changed again while sleeping
  local final_percentage=$(query_item "$NAME" "slider.percentage")
  if [[ "$final_percentage" == "$INFO" ]]; then
    reset_slider "$NAME"
  fi
}

mouse_clicked() {
  if [[ "$NAME" == "volume" ]]; then
    osascript -e "set volume output volume $PERCENTAGE"
  elif [[ "$NAME" == "volume_icon" ]]; then
    # Show or hide the slider
    if [[ "$(query_item volume slider.width)" == "0" ]]; then
      animate_item tanh 30 volume slider.width="$WIDTH"
    else
      reset_slider volume
    fi
  fi
}

case "$SENDER" in
  "volume_change") volume_change ;;
  "mouse.clicked") mouse_clicked ;;
  "mouse.entered") show_slider_knob "$NAME" ;;
  "mouse.exited") hide_slider_knob "$NAME" ;;
esac

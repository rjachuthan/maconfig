#!/bin/bash

# Spotify Module - Plugin
# Handles Spotify playback control and display

source "$CONFIG_DIR/config.sh"

# Control functions
next() {
  osascript -e 'tell application "Spotify" to play next track'
}

back() {
  osascript -e 'tell application "Spotify" to play previous track'
}

play() {
  osascript -e 'tell application "Spotify" to playpause'
}

repeat() {
  local repeat_state=$(osascript -e 'tell application "Spotify" to get repeating')
  if [[ "$repeat_state" == "false" ]]; then
    update_item spotify.repeat icon.highlight=on
    osascript -e 'tell application "Spotify" to set repeating to true'
  else
    update_item spotify.repeat icon.highlight=off
    osascript -e 'tell application "Spotify" to set repeating to false'
  fi
}

shuffle() {
  local shuffle_state=$(osascript -e 'tell application "Spotify" to get shuffling')
  if [[ "$shuffle_state" == "false" ]]; then
    update_item spotify.shuffle icon.highlight=on
    osascript -e 'tell application "Spotify" to set shuffling to true'
  else
    update_item spotify.shuffle icon.highlight=off
    osascript -e 'tell application "Spotify" to set shuffling to false'
  fi
}

# Update display with current track info
update() {
  local playing=1

  if [[ "$(echo "$INFO" | jq -r '.["Player State"]')" == "Playing" ]]; then
    playing=0
    local track="$(echo "$INFO" | jq -r .Name | sed 's/\(.\{20\}\).*/\1.../')"
    local artist="$(echo "$INFO" | jq -r .Artist | sed 's/\(.\{20\}\).*/\1.../')"
    local album="$(echo "$INFO" | jq -r .Album | sed 's/\(.\{25\}\).*/\1.../')"
    local shuffle_state=$(osascript -e 'tell application "Spotify" to get shuffling')
    local repeat_state=$(osascript -e 'tell application "Spotify" to get repeating')
    local cover=$(osascript -e 'tell application "Spotify" to get artwork url of current track')
  fi

  local args=()

  if [[ $playing -eq 0 ]]; then
    # Download cover art
    curl -s --max-time 20 "$cover" -o /tmp/cover.jpg

    # Set track info
    if [[ -z "$artist" ]]; then
      # Podcast format
      add_args args --set spotify.title label="$track" drawing=on
      add_args args --set spotify.album label="Podcast" drawing=on
      add_args args --set spotify.artist label="$album" drawing=on
    else
      # Music format
      add_args args --set spotify.title label="$track" drawing=on
      add_args args --set spotify.album label="$album" drawing=on
      add_args args --set spotify.artist label="$artist" drawing=on
    fi

    # Set controls and cover
    add_args args --set spotify.play icon=􀊆
    add_args args --set spotify.shuffle icon.highlight="$shuffle_state"
    add_args args --set spotify.repeat icon.highlight="$repeat_state"
    add_args args --set spotify.cover background.image="/tmp/cover.jpg" background.color=0x00000000
    add_args args --set spotify.anchor drawing=on
    add_args args --set spotify drawing=on
  else
    # Not playing - hide most elements
    add_args args --set spotify.title drawing=off
    add_args args --set spotify.artist drawing=off
    add_args args --set spotify.anchor drawing=off popup.drawing=off
    add_args args --set spotify.play icon=􀊄
  fi

  batch_update "${args[@]}"
}

# Handle scrubbing through track
scrubbing() {
  local duration_ms=$(osascript -e 'tell application "Spotify" to get duration of current track')
  local duration=$((duration_ms / 1000))
  local target=$((duration * PERCENTAGE / 100))

  osascript -e "tell application \"Spotify\" to set player position to $target"
  update_item spotify.state slider.percentage="$PERCENTAGE"
}

# Update progress slider
scroll() {
  local duration_ms=$(osascript -e 'tell application "Spotify" to get duration of current track')
  local duration=$((duration_ms / 1000))
  local float_time="$(osascript -e 'tell application "Spotify" to get player position')"
  local time=${float_time%.*}

  sketchybar --animate linear 10 \
             --set spotify.state slider.percentage="$((time * 100 / duration))" \
                                 icon="$(date -r "$time" +'%M:%S')" \
                                 label="$(date -r "$duration" +'%M:%S')"
}

# Handle mouse clicks
mouse_clicked() {
  case "$NAME" in
    "spotify.next") next ;;
    "spotify.back") back ;;
    "spotify.play") play ;;
    "spotify.shuffle") shuffle ;;
    "spotify.repeat") repeat ;;
    "spotify.state") scrubbing ;;
    *) exit ;;
  esac
}

# Handle popup
popup() {
  render_popup spotify.anchor "$1"
}

# Main routine
routine() {
  case "$NAME" in
    "spotify.state") scroll ;;
    *) update ;;
  esac
}

# Dispatch events
case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  "mouse.entered") popup on ;;
  "mouse.exited"|"mouse.exited.global") popup off ;;
  "routine") routine ;;
  *) update ;;
esac

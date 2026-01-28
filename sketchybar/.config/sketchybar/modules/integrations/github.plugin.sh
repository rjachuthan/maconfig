#!/bin/bash

# GitHub Module - Plugin
# Fetches and displays GitHub notifications

source "$CONFIG_DIR/config.sh"

update() {
  local notifications="$(gh api notifications 2>/dev/null)"
  local count="$(echo "$notifications" | jq 'length' 2>/dev/null)"

  # Handle null or empty responses
  if [[ -z "$count" || "$count" == "null" ]]; then
    count=0
  fi

  local args=()

  # Set bell icon based on notification count
  if [[ "$notifications" == "[]" || "$count" == "0" ]]; then
    args+=(--set "$NAME" icon="$BELL" label="0")
  else
    args+=(--set "$NAME" icon="$BELL_DOT" label="$count")
  fi

  local prev_count=$(query_item github.bell "label.value" 2>/dev/null)

  # Remove old notification items
  args+=(--remove '/github.notification\.*/')

  local counter=0
  local color=$BLUE
  args+=(--set github.bell icon.color="$color")

  # Parse notifications and create popup items
  while read -r repo url type title; do
    ((counter++))
    local important="$(echo "$title" | grep -iE "(deprecat|break|broke)")"
    color=$BLUE
    local padding=0

    # Handle empty notification
    if [[ -z "$repo" && -z "$title" ]]; then
      repo="Note"
      title="No new notifications"
    fi

    # Set icon and color based on notification type
    local icon=""
    local notification_url=""
    case "$type" in
      "'Issue'")
        color=$GREEN
        icon=$GIT_ISSUE
        notification_url="$(gh api "$(echo "$url" | sed -e "s/^'//" -e "s/'$//")" 2>/dev/null | jq -r .html_url)"
        ;;
      "'Discussion'")
        color=$WHITE
        icon=$GIT_DISCUSSION
        notification_url="https://www.github.com/notifications"
        ;;
      "'PullRequest'")
        color=$MAGENTA
        icon=$GIT_PULL_REQUEST
        notification_url="$(gh api "$(echo "$url" | sed -e "s/^'//" -e "s/'$//")" 2>/dev/null | jq -r .html_url)"
        ;;
      "'Commit'")
        color=$WHITE
        icon=$GIT_COMMIT
        notification_url="$(gh api "$(echo "$url" | sed -e "s/^'//" -e "s/'$//")" 2>/dev/null | jq -r .html_url)"
        ;;
    esac

    # Mark important notifications in red
    if [[ -n "$important" ]]; then
      color=$RED
      icon="􀁞"
      args+=(--set github.bell icon.color="$color")
    fi

    # Create notification item
    args+=(--clone github.notification.$counter github.template
           --set github.notification.$counter label="$(echo "$title" | sed -e "s/^'//" -e "s/'$//")"
                                            icon="$icon $(echo "$repo" | sed -e "s/^'//" -e "s/'$//"):"
                                            icon.padding_left="$padding"
                                            label.padding_right="$padding"
                                            icon.color="$color"
                                            position=popup.github.bell
                                            icon.background.color="$color"
                                            drawing=on
                                            click_script="open $notification_url; sketchybar --set github.bell popup.drawing=off")
  done <<< "$(echo "$notifications" | jq -r '.[] | [.repository.name, .subject.latest_comment_url, .subject.type, .subject.title] | @sh' 2>/dev/null)"

  batch_update "${args[@]}" > /dev/null 2>&1

  # Animate label if count increased
  if [[ $count -gt ${prev_count:-0} ]] 2>/dev/null || [[ "$SENDER" == "forced" ]]; then
    sketchybar --animate tanh 15 --set github.bell label.y_offset=5 label.y_offset=0
  fi
}

popup() {
  render_popup github.bell "$1"
}

# Dispatch events
case "$SENDER" in
  "routine"|"forced") update ;;
  "mouse.entered") popup on ;;
  "mouse.exited"|"mouse.exited.global") popup off ;;
  "mouse.clicked") popup toggle ;;
esac

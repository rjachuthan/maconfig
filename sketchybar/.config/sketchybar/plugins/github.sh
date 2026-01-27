#!/bin/sh

update() {
  source "$HOME/.config/sketchybar/colors.sh"
  source "$HOME/.config/sketchybar/icons.sh"

  NOTIFICATIONS="$(gh api notifications 2>/dev/null)"
  COUNT="$(echo "$NOTIFICATIONS" | jq 'length' 2>/dev/null)"

  if [ -z "$COUNT" ] || [ "$COUNT" = "null" ]; then
    COUNT=0
  fi

  args=()
  if [ "$NOTIFICATIONS" = "[]" ] || [ "$COUNT" = "0" ]; then
    args+=(--set $NAME icon=$BELL label="0")
  else
    args+=(--set $NAME icon=$BELL_DOT label="$COUNT")
  fi

  PREV_COUNT=$(sketchybar --query github.bell | jq -r .label.value 2>/dev/null)

  args+=(--remove '/github.notification\.*/')

  COUNTER=0
  COLOR=$BLUE
  args+=(--set github.bell icon.color=$COLOR)

  while read -r repo url type title
  do
    COUNTER=$((COUNTER + 1))
    IMPORTANT="$(echo "$title" | grep -iE "(deprecat|break|broke)")"
    COLOR=$BLUE
    PADDING=0

    if [ "${repo}" = "" ] && [ "${title}" = "" ]; then
      repo="Note"
      title="No new notifications"
    fi
    case "${type}" in
      "'Issue'") COLOR=$GREEN; ICON=$GIT_ISSUE; URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" 2>/dev/null | jq .html_url)"
      ;;
      "'Discussion'") COLOR=$WHITE; ICON=$GIT_DISCUSSION; URL="https://www.github.com/notifications"
      ;;
      "'PullRequest'") COLOR=$MAGENTA; ICON=$GIT_PULL_REQUEST; URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" 2>/dev/null | jq .html_url)"
      ;;
      "'Commit'") COLOR=$WHITE; ICON=$GIT_COMMIT; URL="$(gh api "$(echo "${url}" | sed -e "s/^'//" -e "s/'$//")" 2>/dev/null | jq .html_url)"
      ;;
    esac

    if [ "$IMPORTANT" != "" ]; then
      COLOR=$RED
      ICON=􀁞
      args+=(--set github.bell icon.color=$COLOR)
    fi

    args+=(--clone github.notification.$COUNTER github.template \
           --set github.notification.$COUNTER label="$(echo "$title" | sed -e "s/^'//" -e "s/'$//")" \
                                            icon="$ICON $(echo "$repo" | sed -e "s/^'//" -e "s/'$//"):" \
                                            icon.padding_left="$PADDING" \
                                            label.padding_right="$PADDING" \
                                            icon.color=$COLOR \
                                            position=popup.github.bell \
                                            icon.background.color=$COLOR \
                                            drawing=on \
                                            click_script="open $URL;
                                                          sketchybar --set github.bell popup.drawing=off")
  done <<< "$(echo "$NOTIFICATIONS" | jq -r '.[] | [.repository.name, .subject.latest_comment_url, .subject.type, .subject.title] | @sh' 2>/dev/null)"

  sketchybar -m "${args[@]}" > /dev/null 2>&1

  if [ $COUNT -gt $PREV_COUNT ] 2>/dev/null || [ "$SENDER" = "forced" ]; then
    sketchybar --animate tanh 15 --set github.bell label.y_offset=5 label.y_offset=0
  fi
}

popup() {
  sketchybar --set $NAME popup.drawing=$1
}

case "$SENDER" in
  "routine"|"forced") update
  ;;
  "mouse.entered") popup on
  ;;
  "mouse.exited"|"mouse.exited.global") popup off
  ;;
  "mouse.clicked") popup toggle
  ;;
esac

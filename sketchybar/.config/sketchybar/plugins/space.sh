#!/bin/sh

update() {
  # Get current aerospace workspace
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)

  # Extract space number from item name (space.X -> X)
  SID=$(echo "$NAME" | sed 's/space\.//')

  SELECTED="false"
  if [ "$SID" = "$FOCUSED_WORKSPACE" ]; then
    SELECTED="true"
  fi

  WIDTH="dynamic"
  if [ "$SELECTED" = "true" ]; then
    WIDTH="0"
  fi

  sketchybar --animate tanh 20 --set $NAME icon.highlight=$SELECTED label.width=$WIDTH
}

mouse_clicked() {
  SID=$(echo "$NAME" | sed 's/space\.//')
  if [ "$BUTTON" = "right" ]; then
    sketchybar --trigger aerospace_workspace_change
  else
    # Focus workspace with aerospace
    aerospace workspace $SID 2>/dev/null
    sketchybar --trigger aerospace_workspace_change
  fi
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac

#!/bin/sh

update() {
  WIDTH="dynamic"
  if [ "$SELECTED" = "true" ]; then
    WIDTH="0"
  fi

  sketchybar --animate tanh 20 --set $NAME icon.highlight=$SELECTED label.width=$WIDTH

}

mouse_clicked() {
  if [ "$BUTTON" = "right" ]; then
    # For aerospace: close workspace (if supported)
    # aerospace workspace --destroy $SID 2>/dev/null
    sketchybar --trigger aerospace_workspace_change
  else
    # Focus workspace with aerospace
    aerospace workspace $SID 2>/dev/null
  fi
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac

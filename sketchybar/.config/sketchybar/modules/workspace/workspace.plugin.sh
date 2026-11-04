#!/bin/bash

# Aerospace Workspace Module - Plugin
# Shows the focused workspace. aerospace passes it as FOCUSED_WORKSPACE on
# workspace change; otherwise (reload, first draw) it is queried directly.

source "$CONFIG_DIR/config.sh"

workspace="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

sketchybar --set "$NAME" label="${workspace:-?}"

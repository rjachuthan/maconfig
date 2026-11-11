#!/bin/bash

# Memory Module - Plugin
# Click the CPU pill for a popup of the top memory consumers (apps grouped by
# bundle, other processes listed per PID), highest first. Each row has a ✕ on
# the right that force kills (SIGKILL) that app; nothing else on the row kills.
#
# A vertical sketchybar popup holds one clickable item per row, so the ✕ column
# is a second, borderless popup (on cpu.percent) laid over the right edge of the
# list popup (on cpu.top). Both items share the same right edge.
#
#   memory.plugin.sh click      toggle the popup
#   memory.plugin.sh kill N     force kill the app shown on row N
#   memory.plugin.sh hover      ✕ hover highlight (mouse.entered / exited)

source "$CONFIG_DIR/config.sh"

MEMORY_PLUGIN="$MODULE_DIR/system/memory.plugin.sh"
LIST_ITEM=cpu.top       # anchor of the list popup
KILL_ITEM=cpu.percent   # anchor of the ✕ column popup
TOP_N=10
NAME_MAX=26

W=300        # list popup row width (content)
MEM_W=70     # memory column width
KILL_W=34    # ✕ column width (blank space reserved on the list rows)

ROWS_STATE="$STATE_DIR/memory_rows"   # row -> "key<TAB>name" of what is shown

# Processes that must never be offered for killing
PROTECTED_RE='/(loginwindow|WindowServer|sketchybar)$'

# Top memory consumers owned by the current user, one per line:
#   rss_kb <TAB> key <TAB> name
# key is the .app bundle path (all its processes summed) or "pid:N".
top_consumers() {
  ps -axo pid=,rss=,comm= -U "$USER" 2>/dev/null | awk -v protected="$PROTECTED_RE" \
    -v helper="$NATIVE_DIR/helper" '
    {
      match($0, /^ *[0-9]+ +[0-9]+ /)
      if (RLENGTH < 0) next
      pid = $1; rss = $2; comm = substr($0, RLENGTH + 1)
      if (comm ~ protected || comm == helper) next
      i = index(comm, ".app/")
      if (i > 0) {
        key = substr(comm, 1, i + 3)
        n = split(key, parts, "/"); name = parts[n]; sub(/\.app$/, "", name)
      } else {
        key = "pid:" pid
        n = split(comm, parts, "/"); name = parts[n]
      }
      mem[key] += rss; label[key] = name
    }
    END { for (k in mem) printf "%d\t%s\t%s\n", mem[k], k, label[k] }
  ' | sort -t$'\t' -k1,1nr | head -n "$TOP_N"
}

format_mem() {
  awk -v kb="$1" 'BEGIN {
    if (kb >= 1048576) printf "%.1f GB", kb / 1048576
    else printf "%d MB", kb / 1024
  }'
}

mem_color() {
  local kb=$1
  if (( kb >= 2097152 )); then echo "$RED"
  elif (( kb >= 1048576 )); then echo "$YELLOW"
  else echo "$WHITE"
  fi
}

build_popup() {
  local rows
  rows=$(top_consumers)

  local base=(
    icon.padding_left=0 icon.padding_right=0
    label.padding_left=0 label.padding_right=0
    background.drawing=off
  )
  local list=(--remove '/memory\..*/')

  # Header (the ✕ column gets a blank cell so the rows stay aligned)
  list+=(--add item memory.header popup.$LIST_ITEM
         --set memory.header "${base[@]}" padding_left=12 padding_right=12
               icon.drawing=off
               label="MEMORY · TOP $TOP_N"
               label.font="$FONT:Heavy:9.0"
               label.color=$GREY
               label.width=$W
               click_script="open -a 'Activity Monitor'; '$MEMORY_PLUGIN' close"
         --add item memory.kill_header popup.$KILL_ITEM
         --set memory.kill_header "${base[@]}" padding_left=0 padding_right=0
               icon.drawing=off label.drawing=off width=$KILL_W)

  : > "$ROWS_STATE"
  local i=0 kb key name
  while IFS=$'\t' read -r kb key name; do
    [[ -z "$key" ]] && continue
    printf '%s\t%s\n' "$key" "$name" >> "$ROWS_STATE"
    local shown="$name"
    (( ${#shown} > NAME_MAX )) && shown="${shown:0:NAME_MAX-1}…"

    # Row: [name] ........ [memory] [blank space under the ✕]
    list+=(--add item "memory.row.$i" popup.$LIST_ITEM
           --set "memory.row.$i" "${base[@]}" padding_left=12 padding_right=$KILL_W
                 icon="$shown"
                 icon.font="$FONT:Semibold:12.5"
                 icon.color=$WHITE
                 icon.width=$((W - MEM_W - KILL_W + 12))
                 icon.align=left
                 label="$(format_mem "$kb")"
                 label.font="$FONT:Semibold:12.5"
                 label.color="$(mem_color "$kb")"
                 label.width=$MEM_W
                 label.align=right
           --add item "memory.kill.$i" popup.$KILL_ITEM
           --set "memory.kill.$i" "${base[@]}" padding_left=0 padding_right=0
                 icon.drawing=off
                 label="􀁡"
                 label.font="$FONT:Bold:13.0"
                 label.color=$GREY
                 label.width=$KILL_W
                 label.align=center
                 script="$MEMORY_PLUGIN hover"
                 click_script="$MEMORY_PLUGIN kill $i"
           --subscribe "memory.kill.$i" mouse.entered mouse.exited)
    ((i++))
  done <<< "$rows"

  sketchybar "${list[@]}" >/dev/null 2>&1
}

popup_style() {
  local common=(popup.align=right popup.horizontal=off popup.height=26 popup.y_offset=6)
  sketchybar --set $LIST_ITEM "${common[@]}" \
             --set $KILL_ITEM "${common[@]}" \
                   popup.background.color=$TRANSPARENT \
                   popup.background.border_width=$POPUP_BORDER_WIDTH \
                   popup.background.border_color=$TRANSPARENT \
                   popup.background.shadow.drawing=off \
                   popup.blur_radius=0
}

open_popup() {
  popup_style
  build_popup
  # The ✕ column must end up above the list, so it is shown second
  sketchybar --set $LIST_ITEM popup.drawing=on
  sketchybar --set $KILL_ITEM popup.drawing=on
}

close_popup() {
  sketchybar --set $KILL_ITEM popup.drawing=off --set $LIST_ITEM popup.drawing=off
}

toggle_popup() {
  if [[ "$(query_item $LIST_ITEM popup.drawing)" == "on" ]]; then
    close_popup
  else
    open_popup
  fi
}

# Force kill what row N showed. The target is re-resolved now, so a reused PID
# or an app that already quit is never hit by mistake.
kill_row() {
  local n=$1 line key name pids=()
  line=$(sed -n "$((n + 1))p" "$ROWS_STATE" 2>/dev/null)
  [[ -z "$line" ]] && return
  IFS=$'\t' read -r key name <<< "$line"

  if [[ "$key" == pid:* ]]; then
    local pid="${key#pid:}" comm
    comm=$(ps -o comm= -p "$pid" 2>/dev/null)
    [[ "${comm##*/}" == "$name" ]] && pids=("$pid")
  else
    while read -r pid; do pids+=("$pid"); done < <(
      ps -axo pid=,comm= -U "$USER" | awk -v prefix="$key/" '
        { match($0, /^ *[0-9]+ /); comm = substr($0, RLENGTH + 1)
          if (index(comm, prefix) == 1) print $1 }')
  fi

  (( ${#pids[@]} )) && kill -9 "${pids[@]}" 2>/dev/null
  sleep 0.5
  build_popup
}

hover() {
  case "$SENDER" in
    mouse.entered) sketchybar --set "$NAME" label.color=$RED ;;
    mouse.exited)  sketchybar --set "$NAME" label.color=$GREY ;;
  esac
}

case "$1" in
  click) toggle_popup ;;
  close) close_popup ;;
  kill)  kill_row "$2" ;;
  hover) hover ;;
esac

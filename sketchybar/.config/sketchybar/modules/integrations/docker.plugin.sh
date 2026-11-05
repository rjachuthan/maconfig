#!/bin/bash

# Docker Module - Plugin
# Polls `docker ps` and shows the number of running containers. Redraws only
# when something changed. The popup lists each container with its host ports.
#   docker.plugin.sh          refresh (routine / docker_update / forced)
#   docker.plugin.sh click    toggle the container popup

source "$CONFIG_DIR/config.sh"

# Max characters of a container name in the popup
NAME_MAX=30

command -v docker >/dev/null 2>&1 || export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

# One running container per line, tab separated: name, ports, status.
# Exits non-zero when the daemon is unreachable.
list_containers() {
  docker ps --format '{{.Names}}\t{{.Ports}}\t{{.Status}}' 2>/dev/null | sort
}

# "0.0.0.0:8080->80/tcp, :::8080->80/tcp, 5432/tcp" -> "8080"
# Only published ports (with a host side) are kept; IPv4/IPv6 duplicates merge.
host_ports() {
  local spec seen=" " out="" port
  local IFS=','
  for spec in $1; do
    spec="${spec# }"
    [[ "$spec" == *"->"* ]] || continue
    port="${spec%%->*}"
    port="${port##*:}"
    [[ "$seen" == *" $port "* ]] && continue
    seen+="$port "
    out+="${out:+ }$port"
  done
  echo "$out"
}

status_color() {
  case "$1" in
    *unhealthy*) echo "$RED" ;;
    *starting*)  echo "$YELLOW" ;;
    *healthy*)   echo "$GREEN" ;;
    *)           echo "$WHITE" ;;
  esac
}

# Rebuild the popup rows from the container list
build_popup() {
  local containers="$1"
  local W=300 NAME_W=170
  local total=0
  [[ -n "$containers" ]] && total=$(echo "$containers" | wc -l | tr -d ' ')
  local args=(--remove '/docker\.popup\..*/')

  local row=(
    icon.padding_left=0 icon.padding_right=0
    label.padding_left=0 label.padding_right=0
    padding_left=12 padding_right=12
    background.drawing=off
  )

  args+=(--add item docker.popup.header popup.docker
         --set docker.popup.header "${row[@]}"
               icon.drawing=off
               label="DOCKER CONTAINERS · $total"
               label.font="$FONT:Heavy:9.0"
               label.color=$GREY
               label.width=$W
               click_script="open -a 'Docker'; sketchybar --set docker popup.drawing=off")

  local i=0 name ports status hp first label_text
  while IFS=$'\t' read -r name ports status; do
    [[ -z "$name" ]] && continue
    (( ${#name} > NAME_MAX )) && name="${name:0:NAME_MAX-1}…"

    hp=$(host_ports "$ports")
    first="${hp%% *}"
    first="${first%%-*}"   # port range "8000-8001" -> "8000"
    if [[ -n "$hp" ]]; then
      label_text=":${hp// /  :}"
    else
      label_text="no ports"
    fi

    local click="sketchybar --set docker popup.drawing=off"
    [[ -n "$first" ]] && click="open 'http://localhost:$first'; $click"

    # Row: [● name] .......... [:host ports]
    args+=(--add item "docker.popup.$i" popup.docker
           --set "docker.popup.$i" "${row[@]}"
                 icon="●  $name"
                 icon.font="$FONT:Semibold:12.5"
                 icon.color="$(status_color "$status")"
                 icon.width=$NAME_W
                 icon.align=left
                 label="$label_text"
                 label.font="$FONT:Semibold:12.5"
                 label.color=$([[ -n "$hp" ]] && echo "$WHITE" || echo "$GREY")
                 label.width=$((W - NAME_W))
                 label.align=right
                 click_script="$click")
    ((i++))
  done <<< "$containers"

  if (( i == 0 )); then
    args+=(--add item docker.popup.empty popup.docker
           --set docker.popup.empty "${row[@]}"
                 icon.drawing=off
                 label="No containers running"
                 label.font="$FONT:Semibold:12.5"
                 label.color=$GREY
                 label.width=$W)
  fi

  sketchybar "${args[@]}" >/dev/null 2>&1
}

update() {
  local containers daemon=on
  containers=$(list_containers)
  docker info >/dev/null 2>&1 || daemon=off

  local key="$daemon|$containers"
  [[ "$key" == "$(load_state docker_containers)" && "$SENDER" == "routine" ]] && return
  save_state docker_containers "$key"

  local drawing=$daemon
  is_zen_mode && drawing=off

  local count=0
  [[ -n "$containers" ]] && count=$(echo "$containers" | wc -l | tr -d ' ')
  local color=$WHITE
  (( count == 0 )) && color=$GREY

  sketchybar --set docker drawing=$drawing label="$count" \
                          icon.color=$color label.color=$color \
             --set gap.docker drawing=$drawing

  if [[ "$daemon" == "off" ]]; then
    sketchybar --set docker popup.drawing=off
  elif [[ "$(query_item docker popup.drawing)" == "on" ]]; then
    build_popup "$containers"
  fi
}

toggle_popup() {
  if [[ "$(query_item docker popup.drawing)" == "on" ]]; then
    sketchybar --set docker popup.drawing=off
    return
  fi
  build_popup "$(list_containers)"
  sketchybar --set docker popup.drawing=on
}

if [[ "$1" == "click" ]]; then
  toggle_popup
else
  update
fi

#!/bin/bash

# Sketchybar library: persistent state, TTL cache and zen mode

# ============================================================================
# Persistent state (survives between plugin runs, cleared on reboot)
# ============================================================================

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sketchybar-state"
mkdir -p "$STATE_DIR"

# Usage: save_state KEY VALUE
save_state() {
  echo "$2" > "$STATE_DIR/$1"
}

# Usage: load_state KEY [DEFAULT]
load_state() {
  if [[ -f "$STATE_DIR/$1" ]]; then
    cat "$STATE_DIR/$1"
  else
    echo "${2:-}"
  fi
}

# ============================================================================
# Cache with TTL
# ============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar"
mkdir -p "$CACHE_DIR"

# Usage: cache_set KEY VALUE [TTL_SECONDS]
cache_set() {
  local ttl="${3:-3600}"
  echo "$(($(date +%s) + ttl))" > "$CACHE_DIR/$1.ttl"
  echo "$2" > "$CACHE_DIR/$1.data"
}

# Prints the cached value, or returns 1 when missing or expired
cache_get() {
  local ttl_file="$CACHE_DIR/$1.ttl" data_file="$CACHE_DIR/$1.data"
  [[ -f "$ttl_file" && -f "$data_file" ]] || return 1
  if (( $(date +%s) < $(cat "$ttl_file") )); then
    cat "$data_file"
  else
    rm -f "$ttl_file" "$data_file"
    return 1
  fi
}

cache_invalidate() {
  rm -f "$CACHE_DIR/$1.ttl" "$CACHE_DIR/$1.data"
}

# ============================================================================
# Zen mode: hides everything except the front app and the clock
# ============================================================================

# Items (and brackets) hidden in zen mode. brew is handled separately because
# it is only shown above its outdated-package threshold, docker because it is
# only shown while the daemon is running.
ZEN_ITEMS="weather gap.weather battery volume volume_icon status gap.status cpu cpu.top cpu.percent cpu.sys cpu.user"

is_zen_mode() {
  [[ "$(load_state zen_mode off)" == "on" ]]
}

enable_zen_mode() {
  save_state zen_mode on
  local args=() item
  for item in $ZEN_ITEMS brew docker gap.docker; do args+=(--set "$item" drawing=off); done
  sketchybar "${args[@]}"
}

disable_zen_mode() {
  save_state zen_mode off
  local args=() item
  for item in $ZEN_ITEMS; do args+=(--set "$item" drawing=on); done
  sketchybar "${args[@]}"
  # Let brew and docker decide their own visibility again
  trigger_event brew_update
  trigger_event docker_update
}

toggle_zen_mode() {
  if is_zen_mode; then disable_zen_mode; else enable_zen_mode; fi
}

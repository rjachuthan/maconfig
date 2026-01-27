#!/bin/bash

# Sketchybar Library - State Management
# Functions for managing persistent state and data

# ============================================================================
# State Storage
# ============================================================================

# State directory
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/sketchybar-state"
mkdir -p "$STATE_DIR"

# ============================================================================
# Persistent State Functions
# ============================================================================

# Save state to file
# Usage: save_state KEY VALUE
# Example: save_state spotify_playing true
save_state() {
  local key="$1"
  local value="$2"
  echo "$value" > "$STATE_DIR/$key"
}

# Load state from file
# Usage: load_state KEY [DEFAULT]
# Example: load_state spotify_playing false
load_state() {
  local key="$1"
  local default="${2:-}"

  if [[ -f "$STATE_DIR/$key" ]]; then
    cat "$STATE_DIR/$key"
  else
    echo "$default"
  fi
}

# Delete state
# Usage: delete_state KEY
delete_state() {
  local key="$1"
  rm -f "$STATE_DIR/$key"
}

# Check if state exists
# Usage: has_state KEY
has_state() {
  local key="$1"
  [[ -f "$STATE_DIR/$key" ]]
}

# Clear all state
# Usage: clear_all_state
clear_all_state() {
  rm -f "$STATE_DIR"/*
}

# ============================================================================
# In-Memory State (for current session)
# ============================================================================

declare -A SESSION_STATE

# Set session state
# Usage: set_session KEY VALUE
set_session() {
  local key="$1"
  local value="$2"
  SESSION_STATE[$key]="$value"
}

# Get session state
# Usage: get_session KEY [DEFAULT]
get_session() {
  local key="$1"
  local default="${2:-}"
  echo "${SESSION_STATE[$key]:-$default}"
}

# Delete session state
# Usage: del_session KEY
del_session() {
  local key="$1"
  unset SESSION_STATE[$key]
}

# Check if session state exists
# Usage: has_session KEY
has_session() {
  local key="$1"
  [[ -n "${SESSION_STATE[$key]}" ]]
}

# ============================================================================
# Cached Data Functions
# ============================================================================

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/sketchybar"
mkdir -p "$CACHE_DIR"

# Cache data with TTL (time to live)
# Usage: cache_set KEY VALUE TTL_SECONDS
# Example: cache_set weather_data "$data" 3600
cache_set() {
  local key="$1"
  local value="$2"
  local ttl="${3:-3600}"  # Default 1 hour
  local expire_time=$(($(date +%s) + ttl))

  echo "$expire_time" > "$CACHE_DIR/${key}.ttl"
  echo "$value" > "$CACHE_DIR/${key}.data"
}

# Get cached data (returns empty if expired)
# Usage: cache_get KEY
cache_get() {
  local key="$1"
  local ttl_file="$CACHE_DIR/${key}.ttl"
  local data_file="$CACHE_DIR/${key}.data"

  if [[ ! -f "$ttl_file" || ! -f "$data_file" ]]; then
    return 1
  fi

  local expire_time=$(cat "$ttl_file")
  local now=$(date +%s)

  if (( now < expire_time )); then
    cat "$data_file"
    return 0
  else
    # Expired, clean up
    rm -f "$ttl_file" "$data_file"
    return 1
  fi
}

# Check if cache is valid
# Usage: cache_valid KEY
cache_valid() {
  local key="$1"
  cache_get "$key" >/dev/null 2>&1
}

# Invalidate cache
# Usage: cache_invalidate KEY
cache_invalidate() {
  local key="$1"
  rm -f "$CACHE_DIR/${key}.ttl" "$CACHE_DIR/${key}.data"
}

# Clear all cache
# Usage: cache_clear
cache_clear() {
  rm -f "$CACHE_DIR"/*.ttl "$CACHE_DIR"/*.data
}

# ============================================================================
# Zen Mode State Management
# ============================================================================

# Get list of items to hide in zen mode
# This is the central source of truth for zen mode items
get_zen_items() {
  echo "apple.logo separator brew github.bell battery volume volume_icon cpu.top cpu.percent cpu.sys cpu.user"
}

# Check if zen mode is active
# Usage: is_zen_mode
is_zen_mode() {
  local state=$(load_state zen_mode off)
  [[ "$state" == "on" ]]
}

# Enable zen mode
# Usage: enable_zen_mode
enable_zen_mode() {
  save_state zen_mode on

  # Hide regular items
  local items=$(get_zen_items)
  for item in $items; do
    hide_item "$item"
  done

  # Hide all spaces except the focused one
  update_zen_spaces
}

# Disable zen mode
# Usage: disable_zen_mode
disable_zen_mode() {
  save_state zen_mode off

  # Show regular items
  local items=$(get_zen_items)
  for item in $items; do
    show_item "$item"
  done

  # Show all spaces
  for i in {1..10}; do
    show_item "space.$i"
  done
}

# Update space visibility in zen mode
# Usage: update_zen_spaces
update_zen_spaces() {
  if ! is_zen_mode; then
    return
  fi

  # Get focused workspace
  local focused=$(aerospace list-workspaces --focused 2>/dev/null)

  # Hide all spaces, show only focused
  for i in {1..10}; do
    if [[ "$i" == "$focused" ]]; then
      show_item "space.$i"
    else
      hide_item "space.$i"
    fi
  done
}

# Toggle zen mode
# Usage: toggle_zen_mode
toggle_zen_mode() {
  if is_zen_mode; then
    disable_zen_mode
  else
    enable_zen_mode
  fi
}

# ============================================================================
# Application State Tracking
# ============================================================================

# Track application playing state
# Usage: set_app_playing APP_NAME true|false
set_app_playing() {
  local app="$1"
  local playing="$2"
  save_state "${app}_playing" "$playing"
}

# Get application playing state
# Usage: get_app_playing APP_NAME
get_app_playing() {
  local app="$1"
  load_state "${app}_playing" "false"
}

# ============================================================================
# Counter Functions
# ============================================================================

# Increment counter
# Usage: increment_counter KEY [AMOUNT]
increment_counter() {
  local key="$1"
  local amount="${2:-1}"
  local current=$(load_state "$key" 0)
  local new=$((current + amount))
  save_state "$key" "$new"
  echo "$new"
}

# Decrement counter
# Usage: decrement_counter KEY [AMOUNT]
decrement_counter() {
  local key="$1"
  local amount="${2:-1}"
  local current=$(load_state "$key" 0)
  local new=$((current - amount))
  [[ $new -lt 0 ]] && new=0
  save_state "$key" "$new"
  echo "$new"
}

# Reset counter
# Usage: reset_counter KEY
reset_counter() {
  local key="$1"
  save_state "$key" 0
}

# Get counter value
# Usage: get_counter KEY
get_counter() {
  local key="$1"
  load_state "$key" 0
}

# ============================================================================
# Timestamp Functions
# ============================================================================

# Record timestamp
# Usage: record_timestamp KEY
record_timestamp() {
  local key="$1"
  save_state "${key}_timestamp" "$(date +%s)"
}

# Get time since timestamp
# Usage: time_since KEY
# Returns: seconds since timestamp, or -1 if not found
time_since() {
  local key="$1"
  local timestamp=$(load_state "${key}_timestamp" "")

  if [[ -z "$timestamp" ]]; then
    echo "-1"
  else
    local now=$(date +%s)
    echo $((now - timestamp))
  fi
}

# Check if timestamp is older than N seconds
# Usage: is_older_than KEY SECONDS
is_older_than() {
  local key="$1"
  local max_age="$2"
  local age=$(time_since "$key")

  [[ $age -ge $max_age ]]
}

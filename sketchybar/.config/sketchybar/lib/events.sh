#!/bin/bash

# Sketchybar Library - Event Handling
# Functions for managing events and subscriptions

# ============================================================================
# Event Subscription Functions
# ============================================================================

# Subscribe item to events
# Usage: subscribe_events ITEM_NAME EVENT1 EVENT2 ...
# Example: subscribe_events battery system_woke power_source_change
subscribe_events() {
  local item="$1"
  shift

  for event in "$@"; do
    sketchybar --subscribe "$item" "$event"
  done
}

# Subscribe item to single event
# Usage: subscribe_event ITEM_NAME EVENT
subscribe_event() {
  local item="$1"
  local event="$2"
  sketchybar --subscribe "$item" "$event"
}

# ============================================================================
# Mouse Event Handlers
# ============================================================================

# Standard mouse click handler dispatcher
# Usage in plugin: handle_mouse_click "$NAME" click_handler
handle_mouse_click() {
  local name="$1"
  local handler="$2"

  if [[ "$SENDER" == "mouse.clicked" ]]; then
    "$handler" "$name"
  fi
}

# Standard mouse enter handler
# Usage in plugin: handle_mouse_enter show_popup
handle_mouse_enter() {
  local handler="$1"

  if [[ "$SENDER" == "mouse.entered" ]]; then
    "$handler"
  fi
}

# Standard mouse exit handler
# Usage in plugin: handle_mouse_exit hide_popup
handle_mouse_exit() {
  local handler="$1"

  if [[ "$SENDER" == "mouse.exited" || "$SENDER" == "mouse.exited.global" ]]; then
    "$handler"
  fi
}

# ============================================================================
# Custom Event Triggers
# ============================================================================

# Trigger a custom event
# Usage: trigger_event EVENT_NAME
# Example: trigger_event spotify_change
trigger_event() {
  local event="$1"
  sketchybar --trigger "$event"
}

# Trigger event after delay
# Usage: trigger_event_delayed EVENT_NAME SECONDS
# Example: trigger_event_delayed volume_reset 2
trigger_event_delayed() {
  local event="$1"
  local delay="$2"

  (
    sleep "$delay"
    trigger_event "$event"
  ) &
}

# ============================================================================
# Event Handler Templates
# ============================================================================

# Standard update handler (called on routine events)
# Usage: create_update_handler FUNCTION_NAME
# Creates a function that calls update() when SENDER matches routine or forced_update
create_update_handler() {
  local func_name="$1"

  eval "
  $func_name() {
    case \"\$SENDER\" in
      routine|forced_update|'') update ;;
    esac
  }
  "
}

# Mouse interaction handler template
# Usage: create_mouse_handler CLICK_FN ENTER_FN EXIT_FN
create_mouse_handler() {
  local click_fn="${1:-}"
  local enter_fn="${2:-}"
  local exit_fn="${3:-}"

  if [[ "$SENDER" == "mouse.clicked" && -n "$click_fn" ]]; then
    "$click_fn"
  elif [[ "$SENDER" == "mouse.entered" && -n "$enter_fn" ]]; then
    "$enter_fn"
  elif [[ ("$SENDER" == "mouse.exited" || "$SENDER" == "mouse.exited.global") && -n "$exit_fn" ]]; then
    "$exit_fn"
  fi
}

# Popup interaction handler
# Usage: create_popup_handler UPDATE_FN ANCHOR_ITEM
create_popup_handler() {
  local update_fn="$1"
  local anchor="${2:-$NAME}"

  case "$SENDER" in
    "mouse.entered")
      render_popup "$anchor" on
      ;;
    "mouse.exited"|"mouse.exited.global")
      render_popup "$anchor" off
      ;;
    "routine"|"forced_update"|"")
      "$update_fn"
      ;;
  esac
}

# ============================================================================
# Debouncing and Throttling
# ============================================================================

# Debounce: Execute function only after delay with no new calls
# Usage: debounce DELAY FUNCTION [ARGS...]
# Example: debounce 2 update_display
declare -A DEBOUNCE_PIDS

debounce() {
  local delay="$1"
  local func="$2"
  shift 2

  # Kill previous debounce process if exists
  local key="${func}_${*}"
  if [[ -n "${DEBOUNCE_PIDS[$key]}" ]]; then
    kill "${DEBOUNCE_PIDS[$key]}" 2>/dev/null
  fi

  # Start new debounce process
  (
    sleep "$delay"
    "$func" "$@"
  ) &

  DEBOUNCE_PIDS[$key]=$!
}

# Throttle: Execute function at most once per interval
# Usage: throttle INTERVAL FUNCTION [ARGS...]
declare -A THROTTLE_TIMES

throttle() {
  local interval="$1"
  local func="$2"
  shift 2

  local key="${func}_${*}"
  local now=$(date +%s)
  local last=${THROTTLE_TIMES[$key]:-0}

  if (( now - last >= interval )); then
    THROTTLE_TIMES[$key]=$now
    "$func" "$@"
  fi
}

# ============================================================================
# Event Loop Helpers
# ============================================================================

# Wait for condition with timeout
# Usage: wait_for_condition CONDITION_FUNCTION TIMEOUT [INTERVAL]
# Returns: 0 if condition met, 1 if timeout
wait_for_condition() {
  local condition_fn="$1"
  local timeout="$2"
  local interval="${3:-0.5}"
  local elapsed=0

  while ! "$condition_fn"; do
    sleep "$interval"
    elapsed=$(echo "$elapsed + $interval" | bc)
    if (( $(echo "$elapsed >= $timeout" | bc -l) )); then
      return 1
    fi
  done

  return 0
}

# Retry function with exponential backoff
# Usage: retry_with_backoff MAX_ATTEMPTS FUNCTION [ARGS...]
retry_with_backoff() {
  local max_attempts="$1"
  local func="$2"
  shift 2

  local attempt=1
  local delay=1

  while (( attempt <= max_attempts )); do
    if "$func" "$@"; then
      return 0
    fi

    if (( attempt < max_attempts )); then
      debug_log "Attempt $attempt failed, retrying in ${delay}s..."
      sleep "$delay"
      delay=$((delay * 2))
    fi

    ((attempt++))
  done

  error_log "Failed after $max_attempts attempts"
  return 1
}

# ============================================================================
# Lifecycle Hooks
# ============================================================================

# Register cleanup function to run on script exit
# Usage: on_exit FUNCTION
on_exit() {
  local func="$1"
  trap "$func" EXIT
}

# Register function to run on specific signal
# Usage: on_signal SIGNAL FUNCTION
on_signal() {
  local signal="$1"
  local func="$2"
  trap "$func" "$signal"
}

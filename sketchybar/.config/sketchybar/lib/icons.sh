#!/bin/bash

# Sketchybar Library - Icon Management
# Functions for managing app icons and icon maps

# ============================================================================
# Icon Map Integration
# ============================================================================

# Path to icon map script
ICON_MAP_SCRIPT="$UTILS_DIR/icon_map.sh"

# Get app icon using icon map
# Usage: get_app_icon APP_NAME
# Example: get_app_icon "Google Chrome"
get_app_icon() {
  local app_name="$1"

  # Check if icon map exists
  if [[ ! -f "$ICON_MAP_SCRIPT" ]]; then
    error_log "Icon map script not found: $ICON_MAP_SCRIPT"
    echo ":default:"
    return 1
  fi

  # Call icon map script
  "$ICON_MAP_SCRIPT" "$app_name"
}

# Get app icon with caching
# Usage: get_app_icon_cached APP_NAME
get_app_icon_cached() {
  local app_name="$1"
  local cache_key="icon_${app_name// /_}"

  # Check cache first
  if has_session "$cache_key"; then
    get_session "$cache_key"
    return 0
  fi

  # Get icon and cache it
  local icon=$(get_app_icon "$app_name")
  set_session "$cache_key" "$icon"
  echo "$icon"
}

# ============================================================================
# App Icon Lookup with Fallbacks
# ============================================================================

# Get icon with fallback
# Usage: get_icon_with_fallback APP_NAME FALLBACK_ICON
get_icon_with_fallback() {
  local app_name="$1"
  local fallback="${2:-:default:}"

  local icon=$(get_app_icon "$app_name")

  if [[ -z "$icon" || "$icon" == ":default:" ]]; then
    echo "$fallback"
  else
    echo "$icon"
  fi
}

# ============================================================================
# Icon Validation
# ============================================================================

# Check if icon is valid (not empty or default)
# Usage: is_valid_icon ICON
is_valid_icon() {
  local icon="$1"
  [[ -n "$icon" && "$icon" != ":default:" ]]
}

# ============================================================================
# Special Icon Handlers
# ============================================================================

# Get system app icon (for system applications)
# Usage: get_system_icon APP_NAME
get_system_icon() {
  local app_name="$1"

  case "$app_name" in
    "Finder") echo "󰀶" ;;
    "System Settings"|"System Preferences") echo "" ;;
    "Activity Monitor") echo "$ACTIVITY" ;;
    "Terminal"|"iTerm"|"WezTerm"|"Kitty") echo "" ;;
    "Safari") echo "󰀹" ;;
    "Mail") echo "" ;;
    "Messages") echo "󰍦" ;;
    "Calendar") echo "" ;;
    "Photos") echo "" ;;
    "Music") echo "" ;;
    "TV") echo "󰑈" ;;
    "Podcasts") echo "" ;;
    "Books") echo "" ;;
    "App Store") echo "" ;;
    *) get_app_icon "$app_name" ;;
  esac
}

# Get development tool icon
# Usage: get_dev_icon APP_NAME
get_dev_icon() {
  local app_name="$1"

  case "$app_name" in
    "Xcode") echo "" ;;
    "Visual Studio Code"|"VSCode"|"Code") echo "󰨞" ;;
    "IntelliJ IDEA") echo "" ;;
    "PyCharm") echo "" ;;
    "WebStorm") echo "" ;;
    "Android Studio") echo "" ;;
    "Docker") echo "" ;;
    "Postman") echo "" ;;
    *) get_app_icon "$app_name" ;;
  esac
}

# ============================================================================
# Icon Clearing
# ============================================================================

# Clear icon cache for all apps
# Usage: clear_icon_cache
clear_icon_cache() {
  # Clear session state for all icon keys
  for key in "${!SESSION_STATE[@]}"; do
    if [[ "$key" == icon_* ]]; then
      del_session "$key"
    fi
  done
}

# Invalidate specific icon cache
# Usage: invalidate_icon_cache APP_NAME
invalidate_icon_cache() {
  local app_name="$1"
  local cache_key="icon_${app_name// /_}"
  del_session "$cache_key"
}

# ============================================================================
# Debug Functions
# ============================================================================

# List all cached icons
# Usage: list_cached_icons
list_cached_icons() {
  echo "Cached Icons:"
  for key in "${!SESSION_STATE[@]}"; do
    if [[ "$key" == icon_* ]]; then
      local app_name="${key#icon_}"
      app_name="${app_name//_/ }"
      echo "  $app_name: ${SESSION_STATE[$key]}"
    fi
  done
}

#!/bin/bash

# Sketchybar Configuration - Central configuration file
# This file contains all paths, constants, and shared settings

# ============================================================================
# Directory Paths
# ============================================================================

export CONFIG_DIR="$HOME/.config/sketchybar"
export LIB_DIR="$CONFIG_DIR/lib"
export THEME_DIR="$CONFIG_DIR/theme"
export MODULE_DIR="$CONFIG_DIR/modules"
export UTILS_DIR="$CONFIG_DIR/utils"
export NATIVE_DIR="$CONFIG_DIR/native"
export HELPERS_DIR="$CONFIG_DIR/helpers"

# Legacy paths (for backward compatibility during migration)
export ITEM_DIR="$CONFIG_DIR/items"
export PLUGIN_DIR="$CONFIG_DIR/plugins"

# ============================================================================
# Font Settings
# ============================================================================

export FONT="SF Pro"  # Needs Regular, Bold, Semibold, Heavy and Black variants
export PADDINGS=3     # All paddings use this value (icon, label, background)

# ============================================================================
# Bar Settings
# ============================================================================

export BAR_HEIGHT=39
export BAR_CORNER_RADIUS=9
export BAR_Y_OFFSET=10
export BAR_MARGIN=10
export BAR_BLUR_RADIUS=20
export BAR_NOTCH_WIDTH=0
export BAR_PADDING_RIGHT=10
export BAR_PADDING_LEFT=10

# ============================================================================
# Default Item Settings
# ============================================================================

export ICON_FONT="$FONT:Bold:14.0"
export LABEL_FONT="$FONT:Semibold:13.0"
export BACKGROUND_HEIGHT=30
export BACKGROUND_CORNER_RADIUS=9
export POPUP_BORDER_WIDTH=2
export POPUP_CORNER_RADIUS=9

# ============================================================================
# Helper Process
# ============================================================================

export HELPER_NAME="git.felix.helper"

# ============================================================================
# Load Core Libraries
# ============================================================================

# Load theme files
source "$THEME_DIR/colors.sh"
source "$THEME_DIR/sf-symbols.sh"

# Load lib files
source "$LIB_DIR/common.sh"
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/events.sh"
source "$LIB_DIR/state.sh"
source "$LIB_DIR/icons.sh"

#!/bin/bash

# Sketchybar central configuration: paths, layout constants, shared styles.
# Sourced by sketchybarrc and by every plugin script.

# ============================================================================
# Paths
# ============================================================================

export CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
export LIB_DIR="$CONFIG_DIR/lib"
export MODULE_DIR="$CONFIG_DIR/modules"
export NATIVE_DIR="$CONFIG_DIR/native"
export HELPERS_DIR="$CONFIG_DIR/helpers"

# ============================================================================
# Fonts
# ============================================================================

export FONT="SF Pro"  # Needs Regular, Bold, Semibold, Heavy and Black variants
export PADDINGS=4     # Default icon, label and item padding

# ============================================================================
# Bar
# ============================================================================

export BAR_HEIGHT=38
export BAR_CORNER_RADIUS=10
export BAR_Y_OFFSET=6
export BAR_MARGIN=12
export BAR_BLUR_RADIUS=30
export BAR_NOTCH_WIDTH=0
export BAR_PADDING_RIGHT=8
export BAR_PADDING_LEFT=8

# ============================================================================
# Item defaults
# ============================================================================

export ICON_FONT="$FONT:Bold:14.0"
export LABEL_FONT="$FONT:Semibold:13.0"
export BACKGROUND_HEIGHT=26         # Pill height
export BACKGROUND_CORNER_RADIUS=6   # Pill radius
export POPUP_BORDER_WIDTH=1
export POPUP_CORNER_RADIUS=8

# ============================================================================
# Helper process
# ============================================================================

export HELPER_NAME="git.felix.helper"

# ============================================================================
# Colors, icons and libraries
# ============================================================================

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"
source "$LIB_DIR/common.sh"
source "$LIB_DIR/state.sh"
source "$LIB_DIR/ui.sh"

# Shared pill style (same fill, hairline, radius and height everywhere)
pill=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
  background.border_width=1
  background.corner_radius=$BACKGROUND_CORNER_RADIUS
  background.height=$BACKGROUND_HEIGHT
  background.drawing=on
)

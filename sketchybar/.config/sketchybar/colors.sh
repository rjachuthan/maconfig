#!/bin/bash
# Sketchybar Colors - Generated from theme
# This file is sourced by sketchybarrc

# Load active theme (fallback to shiny-black if not set)
THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/maconfig/active-theme.sh"
if [[ -f "$THEME_FILE" ]]; then
    source "$THEME_FILE"
else
    # Fallback: shiny-black defaults
    color_background="0f0f12"
    color_foreground="e8e8ed"
    color5="c678dd"
    color8="3e4452"
    color13="e48bff"
    color15="ffffff"
    gradient_start="c678dd"
    gradient_end="e06c9f"
fi

# Convert hex to sketchybar format (0xAARRGGBB)
hex_to_sketchybar() {
    local hex="${1#\#}"
    local alpha="${2:-ff}"
    echo "0x${alpha}${hex}"
}

# Bar colors
export BAR_COLOR=$(hex_to_sketchybar "$color_background" "e6")
export BAR_BORDER_COLOR=$(hex_to_sketchybar "$color8" "80")

# Item colors
export ITEM_BG_COLOR=$(hex_to_sketchybar "$color8" "60")
export ACCENT_COLOR=$(hex_to_sketchybar "$color5" "ff")
export ACCENT_BRIGHT=$(hex_to_sketchybar "$color13" "ff")

# Text colors
export TEXT_COLOR=$(hex_to_sketchybar "$color_foreground" "ff")
export TEXT_BRIGHT=$(hex_to_sketchybar "$color15" "ff")
export TEXT_DIM=$(hex_to_sketchybar "$color8" "ff")

# Gradient for active workspace
export GRADIENT_START=$(hex_to_sketchybar "$gradient_start" "ff")
export GRADIENT_END=$(hex_to_sketchybar "$gradient_end" "ff")

# Transparent
export TRANSPARENT="0x00000000"

# Status colors
export SUCCESS_COLOR=$(hex_to_sketchybar "98c379" "ff")
export WARNING_COLOR=$(hex_to_sketchybar "e5c07b" "ff")
export ERROR_COLOR=$(hex_to_sketchybar "e06c75" "ff")

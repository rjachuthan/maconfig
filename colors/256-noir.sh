#!/bin/bash
# 256 Noir Theme
# Inspired by vim-256noir by andreasvc
# Grayscale minimalist theme with red accents for errors/constants
# pywal-compatible 16-color scheme

# Special colors
export color_background="121212"
export color_foreground="d0d0d0"
export color_cursor="bcbcbc"

# Normal colors (0-7)
export color0="121212"   # Black (background)
export color1="d70000"   # Red (errors/constants)
export color2="8a8a8a"   # Green → medium gray
export color3="af0000"   # Yellow → dark red
export color4="585858"   # Blue → dark gray
export color5="870000"   # Magenta → very dark red
export color6="bcbcbc"   # Cyan → light gray
export color7="d0d0d0"   # White (foreground)

# Bright colors (8-15)
export color8="303030"   # Bright Black (comments/subtle)
export color9="ff0000"   # Bright Red
export color10="b2b2b2"  # Bright Green → lighter gray
export color11="af0000"  # Bright Yellow → dark red
export color12="8a8a8a"  # Bright Blue → medium gray
export color13="870000"  # Bright Magenta → very dark red
export color14="eeeeee"  # Bright Cyan → near white
export color15="ffffff"  # Bright White

# Semantic mappings for templates
export theme_name="256-noir"
export theme_type="dark"

# UI Colors (derived from base 16)
export ui_background="$color0"
export ui_foreground="$color7"
export ui_foreground_bright="$color15"
export ui_accent="$color6"
export ui_accent_bright="$color14"
export ui_border="$color8"
export ui_selection="$color8"

# Status colors
export status_success="$color10"
export status_warning="$color3"
export status_error="$color1"
export status_info="$color4"

# Gradient colors for active elements (grayscale)
export gradient_start="8a8a8a"
export gradient_end="bcbcbc"

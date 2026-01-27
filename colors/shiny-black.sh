#!/bin/bash
# Shiny Black Theme - Primary
# Inspired by deep dark aesthetic with purple/magenta accents
# pywal-compatible 16-color scheme

# Special colors
export color_background="0f0f12"
export color_foreground="e8e8ed"
export color_cursor="c678dd"

# Normal colors (0-7)
export color0="0f0f12"   # Black (background)
export color1="e06c75"   # Red
export color2="98c379"   # Green
export color3="e5c07b"   # Yellow
export color4="61afef"   # Blue
export color5="c678dd"   # Magenta (primary accent)
export color6="56b6c2"   # Cyan
export color7="abb2bf"   # White (dim)

# Bright colors (8-15)
export color8="3e4452"   # Bright Black (comments/subtle)
export color9="ff7b86"   # Bright Red
export color10="b5e890"  # Bright Green
export color11="ffd68a"  # Bright Yellow
export color12="7cc5ff"  # Bright Blue
export color13="e48bff"  # Bright Magenta (accent highlight)
export color14="6dd3e3"  # Bright Cyan
export color15="ffffff"  # Bright White

# Semantic mappings for templates
export theme_name="shiny-black"
export theme_type="dark"

# UI Colors (derived from base 16)
export ui_background="$color0"
export ui_foreground="$color7"
export ui_foreground_bright="$color15"
export ui_accent="$color5"
export ui_accent_bright="$color13"
export ui_border="$color8"
export ui_selection="$color8"

# Status colors
export status_success="$color2"
export status_warning="$color3"
export status_error="$color1"
export status_info="$color4"

# Gradient colors for active elements (purple to pink)
export gradient_start="c678dd"
export gradient_end="e06c9f"

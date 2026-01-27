#!/bin/bash
# Shiny Black Cool - Cyan/Blue accent variant
# pywal-compatible 16-color scheme

# Special colors
export color_background="0f0f12"
export color_foreground="e8e8ed"
export color_cursor="56b6c2"

# Normal colors (0-7)
export color0="0f0f12"   # Black (background)
export color1="e06c75"   # Red
export color2="98c379"   # Green
export color3="e5c07b"   # Yellow
export color4="61afef"   # Blue
export color5="56b6c2"   # Cyan (primary accent)
export color6="c678dd"   # Magenta
export color7="abb2bf"   # White (dim)

# Bright colors (8-15)
export color8="3e4452"   # Bright Black
export color9="ff7b86"   # Bright Red
export color10="b5e890"  # Bright Green
export color11="ffd68a"  # Bright Yellow
export color12="7cc5ff"  # Bright Blue
export color13="6dd3e3"  # Bright Cyan (accent highlight)
export color14="e48bff"  # Bright Magenta
export color15="ffffff"  # Bright White

# Semantic mappings
export theme_name="shiny-black-cool"
export theme_type="dark"

export ui_background="$color0"
export ui_foreground="$color7"
export ui_foreground_bright="$color15"
export ui_accent="$color5"
export ui_accent_bright="$color13"
export ui_border="$color8"
export ui_selection="$color8"

export status_success="$color2"
export status_warning="$color3"
export status_error="$color1"
export status_info="$color4"

export gradient_start="56b6c2"
export gradient_end="61afef"

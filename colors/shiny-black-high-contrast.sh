#!/bin/bash
# Shiny Black High Contrast - Boosted text brightness
# pywal-compatible 16-color scheme

# Special colors
export color_background="0a0a0d"
export color_foreground="f5f5fa"
export color_cursor="d19aff"

# Normal colors (0-7)
export color0="0a0a0d"   # Black (background - deeper)
export color1="ff6b7a"   # Red (brighter)
export color2="a8d989"   # Green (brighter)
export color3="ffd08a"   # Yellow (brighter)
export color4="72c0ff"   # Blue (brighter)
export color5="d19aff"   # Magenta (primary accent - brighter)
export color6="6dd3e3"   # Cyan (brighter)
export color7="d4d8e0"   # White (brighter dim)

# Bright colors (8-15)
export color8="4a5060"   # Bright Black (more visible)
export color9="ff8a96"   # Bright Red
export color10="c5f0a0"  # Bright Green
export color11="ffe5a8"  # Bright Yellow
export color12="98d4ff"  # Bright Blue
export color13="e8b8ff"  # Bright Magenta
export color14="8eeafa"  # Bright Cyan
export color15="ffffff"  # Bright White

# Semantic mappings
export theme_name="shiny-black-high-contrast"
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

export gradient_start="d19aff"
export gradient_end="ff6b9f"

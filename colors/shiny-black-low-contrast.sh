#!/bin/bash
# Shiny Black Low Contrast - Softer, easier on eyes
# pywal-compatible 16-color scheme

# Special colors
export color_background="14141a"
export color_foreground="c8c8d0"
export color_cursor="a87fd4"

# Normal colors (0-7)
export color0="14141a"   # Black (background - slightly lifted)
export color1="c85a63"   # Red (muted)
export color2="85ad6a"   # Green (muted)
export color3="c9a96a"   # Yellow (muted)
export color4="5698d4"   # Blue (muted)
export color5="a87fd4"   # Magenta (primary accent - muted)
export color6="4da0aa"   # Cyan (muted)
export color7="9499a5"   # White (softer)

# Bright colors (8-15)
export color8="3a3f4d"   # Bright Black
export color9="d98189"   # Bright Red
export color10="a5c98a"  # Bright Green
export color11="ddc590"  # Bright Yellow
export color12="7db5e8"  # Bright Blue
export color13="c4a0e8"  # Bright Magenta
export color14="7cc5cf"  # Bright Cyan
export color15="e0e0e8"  # Bright White (not pure white)

# Semantic mappings
export theme_name="shiny-black-low-contrast"
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

export gradient_start="a87fd4"
export gradient_end="c85a80"

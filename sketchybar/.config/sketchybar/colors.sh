#!/bin/bash

# Sketchybar colors (0xAARRGGBB).
# Neutral black and white by default; the accents are for status only
# (low battery, high CPU, extreme temperatures, rain).

export BLACK=0xff0a0a0a
export WHITE=0xffe0e0e0
export GREY=0xff6b6b6b
export RED=0xffff5f87
export GREEN=0xff5fff87
export BLUE=0xff5fafff
export YELLOW=0xffffd75f
export ORANGE=0xffff875f
export CYAN=0xff5fffd7
export TRANSPARENT=0x00000000

# Bar
export BAR_COLOR=0xf2000000          # Near-opaque black floating bar
export BAR_BORDER_COLOR=0xff1f1f1f   # Hairline outline so the bar lifts off dark wallpapers
export ICON_COLOR=$WHITE
export LABEL_COLOR=$WHITE

# Pills
export BACKGROUND_1=0xff111111       # Pill fill
export BACKGROUND_2=0xff262626       # Pill hairline border

# Popups
export POPUP_BACKGROUND_COLOR=0xff0a0a0a
export POPUP_BORDER_COLOR=$BACKGROUND_2

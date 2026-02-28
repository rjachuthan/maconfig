#!/bin/bash
# Cycles through available themes in order.
# Triggered by alt+shift+t via SKHD.

MACONFIG_DIR="${MACONFIG_DIR:-$HOME/.config/maconfig}"
COLORS_DIR="$(dirname "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")")/Codes/mycodes/maconfig/colors"

# Resolve maconfig root relative to this script or fallback to $HOME
SCRIPT_REAL="$(readlink -f "$0" 2>/dev/null || echo "$0")"
MACONFIG_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_REAL")")")"
if [[ ! -d "$MACONFIG_ROOT/colors" ]]; then
    # Try common location
    MACONFIG_ROOT="$HOME/Codes/mycodes/maconfig"
fi

COLORS_DIR="$MACONFIG_ROOT/colors"
THEME_SWITCH="$MACONFIG_ROOT/scripts/theme-switch.sh"
ACTIVE_THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/maconfig/active-theme.sh"

# Ordered list of themes to cycle through
THEMES=(
    "shiny-black"
    "shiny-black-cool"
    "shiny-black-warm"
    "shiny-black-high-contrast"
    "shiny-black-low-contrast"
    "256-noir"
)

# Get current theme
current_theme=""
if [[ -f "$ACTIVE_THEME_FILE" ]]; then
    current_theme=$(grep 'theme_name=' "$ACTIVE_THEME_FILE" | sed 's/.*theme_name="\(.*\)"/\1/')
fi

# Find the next theme in cycle
next_theme="${THEMES[0]}"
for i in "${!THEMES[@]}"; do
    if [[ "${THEMES[$i]}" == "$current_theme" ]]; then
        next_index=$(( (i + 1) % ${#THEMES[@]} ))
        next_theme="${THEMES[$next_index]}"
        break
    fi
done

# Apply the next theme
"$THEME_SWITCH" "$next_theme"

# Show a notification
osascript -e "display notification \"Switched to: $next_theme\" with title \"Theme Cycle\"" 2>/dev/null || true

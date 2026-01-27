#!/bin/bash

# Theme Switcher for maconfig
# Usage: theme-switch.sh <theme-name>
# Example: theme-switch.sh shiny-black

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACONFIG_DIR="$(dirname "$SCRIPT_DIR")"
COLORS_DIR="$MACONFIG_DIR/colors"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ACTIVE_THEME_FILE="$CONFIG_DIR/maconfig/active-theme.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}==>${NC} $1"; }
print_warning() { echo -e "${YELLOW}==>${NC} $1"; }
print_error() { echo -e "${RED}==>${NC} $1"; }

# List available themes
list_themes() {
    echo -e "${MAGENTA}Available themes:${NC}"
    for theme in "$COLORS_DIR"/*.sh; do
        theme_name=$(basename "$theme" .sh)
        if [[ -f "$ACTIVE_THEME_FILE" ]] && grep -q "theme_name=\"$theme_name\"" "$ACTIVE_THEME_FILE" 2>/dev/null; then
            echo -e "  ${GREEN}* $theme_name${NC} (active)"
        else
            echo "    $theme_name"
        fi
    done
}

# Validate theme exists
validate_theme() {
    local theme="$1"
    if [[ ! -f "$COLORS_DIR/$theme.sh" ]]; then
        print_error "Theme '$theme' not found"
        echo ""
        list_themes
        exit 1
    fi
}

# Apply theme
apply_theme() {
    local theme="$1"

    print_status "Applying theme: $theme"

    # Create config directory if needed
    mkdir -p "$(dirname "$ACTIVE_THEME_FILE")"

    # Copy theme to active theme location
    cp "$COLORS_DIR/$theme.sh" "$ACTIVE_THEME_FILE"
    chmod +x "$ACTIVE_THEME_FILE"

    print_success "Theme file updated"
}

# Reload applications
reload_apps() {
    print_status "Reloading applications..."

    # Reload Sketchybar
    if pgrep -x "sketchybar" > /dev/null; then
        print_status "Reloading Sketchybar..."
        sketchybar --reload
        print_success "Sketchybar reloaded"
    fi

    # Reload JankyBorders
    if pgrep -x "borders" > /dev/null; then
        print_status "Restarting JankyBorders..."
        brew services restart borders 2>/dev/null || borders &
        print_success "JankyBorders restarted"
    fi

    # Notify Neovim instances (if using nvim-remote or similar)
    # This is a placeholder - actual implementation depends on your Neovim setup

    # Reload tmux (if running)
    if pgrep -x "tmux" > /dev/null; then
        print_status "Reloading tmux..."
        tmux source-file "$CONFIG_DIR/tmux/tmux.conf" 2>/dev/null || true
        print_success "tmux reloaded"
    fi
}

# Show current theme
show_current() {
    if [[ -f "$ACTIVE_THEME_FILE" ]]; then
        source "$ACTIVE_THEME_FILE"
        echo -e "${MAGENTA}Current theme:${NC} $theme_name"
    else
        echo -e "${YELLOW}No active theme set${NC}"
    fi
}

# Main
main() {
    case "${1:-}" in
        ""|"--list"|"-l")
            list_themes
            echo ""
            show_current
            ;;
        "--current"|"-c")
            show_current
            ;;
        "--help"|"-h")
            echo "Usage: theme-switch.sh [theme-name|option]"
            echo ""
            echo "Options:"
            echo "  -l, --list     List available themes"
            echo "  -c, --current  Show current theme"
            echo "  -h, --help     Show this help"
            echo ""
            echo "Examples:"
            echo "  theme-switch.sh shiny-black"
            echo "  theme-switch.sh shiny-black-cool"
            ;;
        *)
            validate_theme "$1"
            apply_theme "$1"
            reload_apps
            print_success "Theme '$1' applied successfully!"
            ;;
    esac
}

main "$@"

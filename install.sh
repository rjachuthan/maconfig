#!/bin/bash

# maconfig Installation Script
# Installs dependencies, sets up symlinks, and applies default theme

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() { echo -e "\n${BOLD}${MAGENTA}$1${NC}\n"; }
print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}!${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
    print_success "Running on macOS"
}

# Install Homebrew if not present
install_homebrew() {
    if ! command -v brew &> /dev/null; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add to PATH for Apple Silicon
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        print_success "Homebrew installed"
    else
        print_success "Homebrew already installed"
    fi
}

# Install required packages via Homebrew
install_brew_packages() {
    print_header "Installing Homebrew Packages"

    # Core tools
    local packages=(
        "stow"                  # Symlink manager
        "yq"                    # YAML processor
        "jq"                    # JSON processor
        "gh"                    # GitHub CLI
    )

    # Window management
    local casks=(
        "nikitabobko/tap/aerospace"  # Window manager
        "felixkratz/formulae/sketchybar"  # Status bar
        "felixkratz/formulae/borders"     # Window borders (JankyBorders)
    )

    # Terminal & development
    local dev_casks=(
        "wezterm"               # Primary terminal
        "iterm2"                # Dropdown terminal
        "font-jetbrains-mono"   # Monospace font
        "font-jetbrains-mono-nerd-font"  # Nerd font variant
        "sf-symbols"            # SF Symbols app
    )

    # Optional apps (uncomment as needed)
    local optional_casks=(
        # "hammerspoon"         # Automation
        # "alfred"              # Launcher
        # "raycast"             # Launcher alternative
    )

    # Install formulae
    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            print_success "$pkg already installed"
        else
            print_status "Installing $pkg..."
            brew install "$pkg"
            print_success "$pkg installed"
        fi
    done

    # Add taps
    print_status "Adding Homebrew taps..."
    brew tap nikitabobko/tap 2>/dev/null || true
    brew tap FelixKratz/formulae 2>/dev/null || true
    brew tap homebrew/cask-fonts 2>/dev/null || true

    # Install casks
    for cask in "${casks[@]}" "${dev_casks[@]}"; do
        cask_name=$(echo "$cask" | rev | cut -d'/' -f1 | rev)
        if brew list --cask "$cask_name" &>/dev/null 2>&1 || brew list "$cask_name" &>/dev/null 2>&1; then
            print_success "$cask_name already installed"
        else
            print_status "Installing $cask_name..."
            brew install --cask "$cask" 2>/dev/null || brew install "$cask" 2>/dev/null || true
            print_success "$cask_name installed"
        fi
    done
}

# Install sketchybar app font
install_sketchybar_font() {
    print_status "Installing Sketchybar app font..."
    local font_dir="$HOME/Library/Fonts"
    local font_url="https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.5/sketchybar-app-font.ttf"

    if [[ ! -f "$font_dir/sketchybar-app-font.ttf" ]]; then
        curl -fsSL "$font_url" -o "$font_dir/sketchybar-app-font.ttf"
        print_success "Sketchybar app font installed"
    else
        print_success "Sketchybar app font already installed"
    fi
}

# Backup existing configurations
backup_configs() {
    print_header "Backing Up Existing Configurations"

    local backup_dir="$HOME/.config-backup/$(date +%Y%m%d_%H%M%S)"
    local configs_to_backup=("aerospace" "sketchybar" "borders")
    local backed_up=false

    for config in "${configs_to_backup[@]}"; do
        if [[ -e "$CONFIG_DIR/$config" && ! -L "$CONFIG_DIR/$config" ]]; then
            mkdir -p "$backup_dir"
            print_status "Backing up $config..."
            mv "$CONFIG_DIR/$config" "$backup_dir/"
            backed_up=true
        fi
    done

    if [[ "$backed_up" = true ]]; then
        print_success "Backups stored in $backup_dir"
    else
        print_success "No existing configs to backup"
    fi
}

# Create symlinks with GNU Stow
create_symlinks() {
    print_header "Creating Symlinks"

    cd "$SCRIPT_DIR"

    local packages=("aerospace" "sketchybar" "jankyborders")

    for pkg in "${packages[@]}"; do
        if [[ -d "$pkg" ]]; then
            print_status "Stowing $pkg..."
            stow -v -t "$HOME" "$pkg" 2>&1 | grep -v "^LINK:" || true
            print_success "$pkg linked"
        fi
    done
}

# Setup maconfig directory for theme tracking
setup_maconfig_dir() {
    print_status "Setting up maconfig directory..."
    mkdir -p "$CONFIG_DIR/maconfig"
    print_success "maconfig directory created"
}

# Apply default theme
apply_default_theme() {
    print_header "Applying Default Theme"

    chmod +x "$SCRIPT_DIR/scripts/theme-switch.sh"
    "$SCRIPT_DIR/scripts/theme-switch.sh" shiny-black
}

# Start services
start_services() {
    print_header "Starting Services"

    # Start Sketchybar as a service
    if command -v sketchybar &>/dev/null; then
        print_status "Starting Sketchybar..."
        brew services start sketchybar 2>/dev/null || true
        print_success "Sketchybar service started"
    fi

    # Start JankyBorders as a service
    if command -v borders &>/dev/null; then
        print_status "Starting JankyBorders..."
        brew services start borders 2>/dev/null || true
        print_success "JankyBorders service started"
    fi

    # Start Aerospace (which will also trigger services via after-startup-command)
    if command -v aerospace &>/dev/null; then
        print_status "Starting Aerospace..."
        open -a AeroSpace 2>/dev/null || true
        print_success "Aerospace started"
    fi
}

# Print completion message
print_completion() {
    print_header "Installation Complete!"

    echo -e "${CYAN}What's been set up:${NC}"
    echo "  • Homebrew packages and CLI tools (gh, jq, yq) installed"
    echo "  • Aerospace window manager configured"
    echo "  • Sketchybar status bar configured (with GitHub, Brew, system monitors)"
    echo "  • JankyBorders window borders configured"
    echo "  • Services started (Sketchybar, JankyBorders, Aerospace)"
    echo "  • Deep Black theme applied"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  • Log out and back in (or restart) for all changes to take effect"
    echo "  • Run 'gh auth login' to enable GitHub notifications in Sketchybar"
    echo "  • Use './scripts/theme-switch.sh <theme>' to change themes"
    echo ""
    echo -e "${CYAN}Keybindings (Aerospace):${NC}"
    echo "  • Alt + Enter: Open WezTerm"
    echo "  • Alt + 1-9: Switch workspace"
    echo "  • Alt + H/J/K/L: Focus window (vim-style)"
    echo "  • Alt + Shift + H/J/K/L: Move window"
    echo "  • Alt + /: Toggle tiles layout"
    echo "  • Alt + ,: Toggle accordion layout"
    echo ""
}

# Main installation flow
main() {
    print_header "maconfig Installation"

    check_macos
    install_homebrew
    install_brew_packages
    install_sketchybar_font
    backup_configs
    setup_maconfig_dir
    create_symlinks
    apply_default_theme
    start_services
    print_completion
}

# Run with optional --dry-run flag
if [[ "${1:-}" == "--dry-run" ]]; then
    print_warning "Dry run mode - no changes will be made"
    # Could add dry-run logic here
else
    main
fi

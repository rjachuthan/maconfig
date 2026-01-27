# maconfig

A unified macOS dotfiles system with dynamic theme switching.

## Features

- **GNU Stow-based** symlink management for clean, modular configs
- **Dynamic theme switching** across all applications
- **Deep Black theme** with vibrant accents and zen mode
- **Pywal-compatible** 16-color scheme system
- **Window borders** with JankyBorders integration
- **Modular Sketchybar** with GitHub notifications, Brew updates, and system monitoring

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/maconfig.git ~/.config/maconfig
cd ~/.config/maconfig

# Run installer
./install.sh
```

## Theme Switching

```bash
# List available themes
./scripts/theme-switch.sh --list

# Apply a theme
./scripts/theme-switch.sh shiny-black
./scripts/theme-switch.sh shiny-black-cool
./scripts/theme-switch.sh shiny-black-warm
```

## Structure

```
maconfig/
├── colors/                 # Theme color schemes (16 colors each)
│   ├── shiny-black.sh
│   ├── shiny-black-cool.sh
│   ├── shiny-black-warm.sh
│   └── ...
├── aerospace/              # Stow package: window manager
│   └── .config/aerospace/
├── sketchybar/             # Stow package: status bar
│   └── .config/sketchybar/
├── jankyborders/           # Stow package: window borders
│   └── .config/borders/
├── scripts/                # Utility scripts
│   └── theme-switch.sh
└── install.sh              # Bootstrap script
```

## Keybindings (Aerospace)

| Key | Action |
|-----|--------|
| `Alt + Enter` | Open WezTerm |
| `Alt + 1-9` | Switch to workspace |
| `Alt + H/J/K/L` | Focus window (vim-style) |
| `Alt + Shift + H/J/K/L` | Move window |
| `Alt + Shift + 1-9` | Move window to workspace |
| `Alt + Tab` | Previous workspace |
| `Alt + /` | Toggle tiles layout |
| `Alt + ,` | Toggle accordion layout |
| `Alt + -` | Resize window smaller |
| `Alt + =` | Resize window larger |
| `Alt + Shift + ;` | Enter service mode |

## Applications

**Configured:**
- Aerospace (window manager)
- Sketchybar (status bar with modules)
- JankyBorders (window borders)

**Sketchybar Modules:**
- System: Battery, CPU, Volume
- Integrations: GitHub notifications, Brew updates
- Apps: Front app, Spotify
- Workspace: Aerospace spaces
- UI: Calendar, Apple menu, Zen mode

**Planned:**
- Neovim
- Tmux
- WezTerm
- Yazi
- ZSH

## Requirements

- macOS
- Homebrew (installed automatically)
- GNU Stow
- yq (YAML processor)
- jq (JSON processor)
- gh (GitHub CLI)

**Optional but recommended:**
- WezTerm or iTerm2
- SF Symbols app

## License

MIT

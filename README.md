# maconfig

A unified macOS dotfiles system with dynamic theme switching.

## Features

- **GNU Stow-based** symlink management for clean, modular configs
- **Dynamic theme switching** across all applications
- **Shiny Black theme** with variants (cool, warm, high/low contrast)
- **Pywal-compatible** 16-color scheme system

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
| `Alt + /` | Toggle tile/accordion layout |

## Applications

**Configured:**
- Aerospace (window manager)
- Sketchybar (status bar)

**Planned:**
- Neovim
- Tmux
- WezTerm
- Yazi
- ZSH
- JankyBorders

## Requirements

- macOS
- Homebrew (installed automatically)
- GNU Stow
- yq (YAML processor)

## License

MIT

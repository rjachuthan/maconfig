# maconfig

Personal dotfiles for macOS (with a few Windows pieces), managed with
[GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a
Stow package that mirrors the layout of `$HOME`.

## Quick Start

```bash
git clone <this-repo-url> ~/.config/maconfig
cd ~/.config/maconfig

# Full bootstrap (Homebrew packages, fonts, symlinks, services)
./install.sh

# Or link individual packages
stow -t "$HOME" <package>   # e.g. stow -t "$HOME" tmux
```

`.stowrc` already sets `--target=$HOME`. `install.sh` backs up existing
`aerospace`, `sketchybar`, `borders` and `nvim` configs to
`~/.config-backup/<timestamp>`, then stows `aerospace`, `sketchybar`,
`jankyborders`, `neovim` and `skhd`. Other packages are stowed manually.

## Packages

| Package        | Target                          | Description                                     |
| -------------- | ------------------------------- | ----------------------------------------------- |
| `aerospace`    | `~/.config/aerospace`           | Tiling window manager                           |
| `sketchybar`   | `~/.config/sketchybar`          | Status bar (modular items and plugins)          |
| `jankyborders` | `~/.config/borders`             | Window borders                                  |
| `skhd`         | `~/.config/skhd`                | Global hotkeys (app launchers, reload, lock)    |
| `ghostty`      | `~/.config/ghostty`             | Terminal (used for its quick terminal)          |
| `wezterm`      | `~/.config/wezterm`             | Terminal                                        |
| `alacritty`    | `~/.config/alacritty`           | Terminal                                        |
| `kitty`        | `~/.config/kitty`               | Terminal                                        |
| `tmux`         | `~/.config/tmux`                | Terminal multiplexer                            |
| `neovim`       | `~/.config/nvim`                | Lua config using lazy.nvim                      |
| `yazi`         | `~/.config/yazi`                | File manager (flavors, plugins, keymap)         |
| `zsh`          | `~/.config/zsh`, `~/.local/bin` | Shell config, `tmux-sessionizer`, `migrate.sh`  |
| `qutebrowser`  | `~/.qutebrowser`                | Keyboard-driven browser                         |
| `ipython`      | `~/.ipython`                    | Databricks profile startup script               |
| `claude`       | `~/.claude`                     | Claude Code status line (`statusline.js`)       |
| `pi`           | `~/.pi/agent`                   | Pi agent settings, extensions, theme, skills    |
| `powershell`   | `~/Documents/PowerShell`        | Windows profile and Oh My Posh theme            |

## Linking on Windows

GNU Stow is a macOS/Linux tool, so on Windows the same result is achieved by
creating **symbolic links** by hand (or with a script). A symbolic link is a
filesystem entry that points to a file or directory elsewhere, so edits made
through `$HOME` land in this repo. Windows offers three kinds:

| Type          | Points to              | Needs elevation?                      | Notes                                      |
| ------------- | ---------------------- | ------------------------------------- | ------------------------------------------ |
| Symbolic link | File or directory      | Admin, or Developer Mode turned on    | Closest to what Stow creates               |
| Junction      | Directory only         | No                                    | Local drives only, absolute target path    |
| Hard link     | File only              | No                                    | Same volume only, breaks if file replaced  |

Enable **Settings > System > For developers > Developer Mode** once so symbolic
links work without an elevated shell. Otherwise run PowerShell as
administrator. Use junctions for directories if you want to avoid both.

Run these in PowerShell 7 from the repo root. Each Stow package maps its inner
path onto `$HOME`:

```powershell
$repo = (Get-Location).Path

# Directory symlink (pi agent config -> ~/.pi/agent)
New-Item -ItemType SymbolicLink `
  -Path "$HOME\.pi\agent" `
  -Target "$repo\pi\.pi\agent"

# File symlink (PowerShell profile)
New-Item -ItemType SymbolicLink `
  -Path "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" `
  -Target "$repo\powershell\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# Junction alternative, no elevation needed (directories only)
New-Item -ItemType Junction `
  -Path "$HOME\.claude" `
  -Target "$repo\claude\.claude"
```

Notes:

- The `-Path` must not already exist. Move or delete the existing file or
  directory first (back it up if it holds local state).
- Create parent directories first, for example
  `New-Item -ItemType Directory -Force "$HOME\.pi"`.
- Some tools read from a different location on Windows. Neovim uses
  `$env:LOCALAPPDATA\nvim` rather than `~/.config/nvim`, so point the link
  there.
- Link single files or subdirectories when the target directory also holds
  machine-local data (`auth.json`, `sessions/`, `models-store.json`), so those
  stay out of the repo.
- Remove a link with `(Get-Item <path>).Delete()` or `Remove-Item <path>`.
  Deleting a symlink or junction does not delete the repo contents.
- Check what a path points to with `(Get-Item <path>).Target`.

## Keybindings

### Aerospace

| Key                         | Action                           |
| --------------------------- | -------------------------------- |
| `Alt + Enter`               | Open Ghostty                     |
| `Alt + 1-9`                 | Switch to workspace              |
| `Alt + W/T/B/C/V/G`         | Switch to named workspace        |
| `Alt + H/J/K/L`             | Focus window (vim-style)         |
| `Alt + Shift + H/J/K/L`     | Move window                      |
| `Alt + Shift + 1-9`         | Move window to workspace         |
| `Alt + Shift + W/T/B/C/V/G` | Move window to named workspace   |
| `Alt + Tab`                 | Previous workspace               |
| `Alt + Shift + Tab`         | Move workspace to next monitor   |
| `Alt + /`                   | Toggle tiles layout              |
| `Alt + ,`                   | Toggle accordion layout          |
| `Alt + -` / `Alt + =`       | Resize window smaller / larger   |
| `Alt + Shift + ;`           | Enter service mode               |

### SKHD

| Key                    | Action                  |
| ---------------------- | ----------------------- |
| `Alt + Shift + Return` | Open WezTerm            |
| `Alt + Shift + B`      | Open Zen Browser        |
| `Alt + Shift + O`      | Open Obsidian           |
| `Alt + Shift + G`      | Open Google Chrome      |
| `Alt + Shift + C`      | Open Cursor             |
| `Alt + Shift + V`      | Open Visual Studio Code |
| `Alt + Shift + W`      | Open WhatsApp           |
| `Alt + Shift + X`      | Lock screen             |
| `Alt + Shift + R`      | Reload Sketchybar       |

See `skhd/.config/skhd/skhdrc` for the complete list.

## Sketchybar Modules

Modules live in `sketchybar/.config/sketchybar/modules/`, grouped by area:

- **System:** battery, CPU, volume
- **Apps:** front app
- **Integrations:** weather, Homebrew updates
- **Workspace:** Aerospace spaces (with a zen-mode variant)
- **UI:** calendar, Apple menu, zen mode

Colors are defined in `theme/colors.sh` and icons in `theme/sf-symbols.sh`.
The native CPU helper in `native/` is built with `make`.

## Requirements

- macOS
- Homebrew (installed by `install.sh`)
- GNU Stow, `yq`, `jq`, `gh`
- Aerospace, Sketchybar, JankyBorders, skhd
- JetBrains Mono Nerd Font and the SF Symbols app

`install.sh` also installs WezTerm and iTerm2. Ghostty is installed separately.

## License

MIT

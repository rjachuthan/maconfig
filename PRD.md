# Product Requirements Document (PRD)
## Automated macOS Dotfiles System with Dynamic Theme Switching

## 1. Project Overview

### 1.1 Objective
Create a unified, Git-managed dotfiles system for macOS that consolidates all
configuration files into a single repository with dynamic theme switching
capabilities across all applications.

### 1.2 Scope
- Migrate existing configurations from scattered locations to centralized
  dotfiles repository
- Implement GNU Stow-based symlink management
- Build a minimal, pywal-inspired color scheme system
- Create theme switching mechanism that updates all applications simultaneously
- Set up proper Git repository with branching strategy for experimentation

### 1.3 Target Applications
**Currently Configured:**
- Aerospace (window manager)
- Sketchybar (status bar)

**To Be Configured:**
- Neovim (text editor)
- Tmux (terminal multiplexer)
- Yazi (file manager)
- skhd (hotkey daemon)
- Hammerspoon (automation tool)
- Terminal emulator (WezTerm, Kitty, or iTerm2)
- ZSH shell
- JankyBorders (window borders)
- Alfred (launcher)
- Git (version control)

## 2. Repository Structure Requirements

### 2.1 Root Layout
The repository must support:
- Individual application packages compatible with GNU Stow
- Centralized color scheme management
- Template-based configuration generation
- Installation and bootstrap scripts
- Documentation with screenshots and setup instructions

### 2.2 Color System Architecture
Must implement a three-layer system:
1. **Minimal color schemes** - Only 16 colors per theme (pywal format)
2. **Base configurations** - Non-color settings shared across themes
3. **Application templates** - Per-app configs that consume colors and base settings

### 2.3 ZSH Configuration Location
All ZSH files must be placed in `~/.config/zsh/` instead of home directory,
following Linux conventions. This includes `.zshrc`, `.zshenv`, `.zprofile`,
`.zlogin`, and `.zlogout`.

## 3. Color Scheme System

### 3.1 Primary Theme: "Shiny Black"
Design a dark theme inspired by the reference image provided, featuring:
- Deep black background (not pure `#000000`, slightly lifted)
- Purple/magenta as primary accent color
- Glossy, vibrant colors that pop against dark background
- High contrast between elements
- Support for glow/shadow effects where applicable

### 3.2 Theme Variants
Create the following variations of Shiny Black:
- **shiny-black-cool**: Cyan/blue accent colors
- **shiny-black-warm**: Orange/coral accent colors
- **shiny-black-high-contrast**: Boosted text brightness
- **shiny-black-low-contrast**: Softer contrast for aesthetics

### 3.3 Additional Theme Support
System must support easy addition of:
- Flexoki (dark and light variants)
- Poimandres
- Future custom themes

### 3.4 Color Scheme Format
Each theme file should contain only:
- 16 terminal colors (color0 through color15)
- No application-specific settings
- No opacity, spacing, or other non-color configuration

### 3.5 Color Mapping Strategy
The system must intelligently map 16 base colors to semantic names for use in templates:
- Background/foreground colors
- Accent colors for active states
- UI element colors (borders, selections, cursors)
- Status colors (success, warning, error, info)

## 4. Configuration Management

### 4.1 Base Configuration Files
Create separate base configuration files for:
- Dark themes (opacity, blur, spacing, borders, fonts)
- Light themes
- Per-application overrides (e.g., Sketchybar-specific settings)

These files must contain ONLY non-color settings that remain consistent across theme changes.

### 4.2 Template System
Generate application configurations from templates that:
- Reference color variables from active theme
- Import base configuration settings
- Support application-specific overrides
- Include metadata (theme name, generation timestamp)

### 4.3 Stow Integration
Each application package must:
- Mirror the home directory structure correctly
- Be independently stowable/unstowable
- Not conflict with other packages
- Support selective installation

## 5. Theme Switching Mechanism

### 5.1 Core Functionality
Build a theme switcher that:
- Accepts theme name as parameter
- Validates theme exists before applying
- Generates all application configs from templates
- Reloads affected applications
- Tracks currently active theme
- Provides feedback on success/failure

### 5.2 Application Reload Requirements
After theme switch, the system must reload:
- Terminal emulator colors
- Sketchybar
- JankyBorders
- Neovim (if running)
- Tmux (if running)
- Any other applications that support live reload

### 5.3 Future Enhancement Placeholder
Design the system to eventually support:
- Interactive theme picker (CLI-based with preview)
- Alfred workflow integration
- Quick theme switching via hotkey

## 6. Special Requirements

### 6.1 Dropdown Terminal
Implement a Guake-style dropdown terminal that:
- Appears from top of screen on hotkey
- Overlays current workspace
- Maintains persistent session
- Integrates with tiling window manager

Choose the most suitable approach from:
- Hammerspoon + iTerm2 hotkey window
- skhd + Aerospace + terminal emulator
- iTerm2 native hotkey window feature
- Other viable solution

### 6.2 Sketchybar Aesthetic Requirements
Match the visual style from the reference image:
- Pill-shaped items with rounded corners
- Glossy appearance with blur effects
- Purple-highlighted active workspace indicator
- Proper spacing between bar items
- Translucent background with strong blur
- Shadow/glow effects on active elements

### 6.3 System-wide Font Configuration
Standardize fonts across all applications:
- Monospace: JetBrains Mono (with ligatures)
- Sans-serif: SF Pro (system font)
- Consistent sizing: 13pt normal, 12pt for bars

### 6.4 macOS Defaults Script
Create a script to set preferred macOS system defaults:
- Dock behavior
- Trackpad settings
- Keyboard repeat rates
- Finder preferences
- Other quality-of-life system settings

## 7. Installation & Bootstrap

### 7.1 Initial Setup Requirements
The bootstrap process must:
- Check for required dependencies (Stow, yq, etc.)
- Offer to install missing tools via Homebrew
- Backup existing configurations before overwriting
- Set up `/etc/zshenv` for ZDOTDIR (requires sudo)
- Initialize Git repository if not already done
- Apply default theme
- Create symbolic links via Stow

### 7.2 Brewfile
Generate a Brewfile that tracks all installed tools and applications for reproducibility.

### 7.3 Uninstallation Support
Provide mechanism to:
- Remove all symlinks cleanly
- Restore backed-up configurations
- Optionally remove installed dependencies

## 8. Git Workflow

### 8.1 Branch Strategy
Set up branches for:
- `main` - stable, tested configurations
- `experiment/*` - feature testing branches
- Example: `experiment/sketchybar-redesign`, `experiment/neovim-plugins`

### 8.2 Documentation
Repository must include:
- README with installation instructions
- Screenshots of current setup
- Per-application configuration notes
- Theme showcase with previews
- Troubleshooting guide
- Contribution guidelines (for personal reference)

## 9. Success Criteria

### 9.1 Phase 1 - Foundation
- [ ] Repository structure created with Stow compatibility
- [ ] Existing Aerospace and Sketchybar configs migrated
- [ ] Shiny Black theme implemented with all variants
- [ ] Theme switcher functional for current apps
- [ ] ZSH successfully moved to `~/.config/zsh/`

### 9.2 Phase 2 - Expansion
- [ ] All listed applications configured and themed
- [ ] Dropdown terminal implemented and working
- [ ] Base configuration system proven with multiple themes
- [ ] Flexoki and Poimandres themes added
- [ ] JankyBorders integrated and themed

### 9.3 Phase 3 - Polish
- [ ] Sketchybar matches reference aesthetic
- [ ] All applications reload properly on theme switch
- [ ] Documentation complete with screenshots
- [ ] Brewfile tracks all dependencies
- [ ] Bootstrap script handles fresh install cleanly

## 10. Technical Constraints

### 10.1 Platform
- macOS only (current machine)
- Must work with GNU Stow on macOS

### 10.2 Dependencies
Acceptable to require installation of:
- Homebrew
- GNU Stow
- yq (YAML processor)
- Python 3 (if needed for generator scripts)
- Any other necessary tools

### 10.3 Compatibility
- Support current versions of all listed applications
- No assumptions about future API/config format stability
- Design for easy updates when applications change

## 11. Out of Scope

The following are explicitly NOT part of this initial implementation:
- GUI-based theme picker/editor
- Theme sharing/downloading from community
- Automatic theme switching based on time of day
- Cross-platform support (Linux/Windows)
- Neovim plugin management (use existing solution)
- Application installation automation beyond Brewfile

## 12. Deliverables

Upon completion, provide:
1. Fully functional dotfiles repository
2. Working theme system with all requested themes
3. Installation/bootstrap script
4. Theme switcher script
5. Complete documentation
6. Test procedure results showing all features work

## 13. Notes for Implementation

- Prioritize clean architecture over immediate feature completeness
- Use existing conventions and best practices from dotfiles community
- Test each application's configuration independently before integration
- Keep color scheme files as minimal as possible
- Make the system easy to extend with new themes and applications
- Ensure Git repository is clean with appropriate `.gitignore`

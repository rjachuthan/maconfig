#!/bin/bash
# ZSH Configuration Migration Script
# Migrates existing ZSH config to stow-managed setup

set -e  # Exit on error

REPO_DIR="$HOME/Codes/mycodes/maconfig"
BACKUP_DIR="$HOME/zsh-backup-$(date +%Y%m%d-%H%M%S)"

echo "🔧 ZSH Configuration Migration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Check if /etc/zshenv exists
if [[ ! -f /etc/zshenv ]]; then
  echo "❌ ERROR: /etc/zshenv does not exist!"
  echo
  echo "You need to create it first:"
  echo "  sudo tee /etc/zshenv << 'EOF'"
  echo '  export ZDOTDIR="$HOME/.config/zsh"'
  echo "  EOF"
  echo
  exit 1
fi

# Verify ZDOTDIR is set correctly
if ! grep -q 'ZDOTDIR.*\.config/zsh' /etc/zshenv; then
  echo "⚠️  WARNING: /etc/zshenv exists but may not set ZDOTDIR correctly"
  echo "   Current content:"
  cat /etc/zshenv
  echo
  read -p "Continue anyway? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Create backup
echo "📦 Creating backup at: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

if [[ -d ~/.config/zsh ]]; then
  cp -r ~/.config/zsh "$BACKUP_DIR/"
  echo "   ✓ Backed up ~/.config/zsh"
fi

if [[ -f ~/.local/bin/env ]]; then
  cp ~/.local/bin/env "$BACKUP_DIR/env"
  echo "   ✓ Backed up ~/.local/bin/env"
fi

if [[ -f ~/.zshrc ]]; then
  cp ~/.zshrc "$BACKUP_DIR/.zshrc-old"
  echo "   ✓ Backed up ~/.zshrc (old)"
fi

echo

# Remove existing files
echo "🗑️  Removing existing configuration files"

if [[ -f ~/.zshrc ]]; then
  rm ~/.zshrc
  echo "   ✓ Removed ~/.zshrc (obsolete)"
fi

if [[ -f ~/.config/zsh/.zshrc ]]; then
  rm ~/.config/zsh/.zshrc
  echo "   ✓ Removed ~/.config/zsh/.zshrc"
fi

if [[ -f ~/.config/zsh/.zprofile ]]; then
  rm ~/.config/zsh/.zprofile
  echo "   ✓ Removed ~/.config/zsh/.zprofile"
fi

if [[ -f ~/.local/bin/env ]]; then
  rm ~/.local/bin/env
  echo "   ✓ Removed ~/.local/bin/env"
fi

echo

# Stow the package
echo "🔗 Creating symlinks with GNU Stow"
cd "$REPO_DIR"

if stow zsh; then
  echo "   ✓ Stowed zsh package successfully"
else
  echo "   ❌ Stow failed! Restoring backup..."
  if [[ -f "$BACKUP_DIR/.config/zsh/.zshrc" ]]; then
    cp "$BACKUP_DIR/.config/zsh/.zshrc" ~/.config/zsh/
    cp "$BACKUP_DIR/.config/zsh/.zprofile" ~/.config/zsh/
    cp "$BACKUP_DIR/env" ~/.local/bin/env
  fi
  echo "   Backup restored. Please check for conflicts."
  exit 1
fi

echo

# Verify symlinks
echo "✅ Verifying symlinks"

if [[ -L ~/.config/zsh/.zshrc ]]; then
  echo "   ✓ ~/.config/zsh/.zshrc is a symlink"
else
  echo "   ❌ ~/.config/zsh/.zshrc is NOT a symlink"
fi

if [[ -L ~/.config/zsh/.zprofile ]]; then
  echo "   ✓ ~/.config/zsh/.zprofile is a symlink"
else
  echo "   ❌ ~/.config/zsh/.zprofile is NOT a symlink"
fi

if [[ -L ~/.local/bin/env ]]; then
  echo "   ✓ ~/.local/bin/env is a symlink"
else
  echo "   ❌ ~/.local/bin/env is NOT a symlink"
fi

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Migration complete!"
echo
echo "Backup saved to: $BACKUP_DIR"
echo
echo "Next steps:"
echo "  1. Run 'exec zsh' to reload your shell"
echo "  2. Test that everything works (aliases, completions, etc.)"
echo "  3. If something is wrong, run: cd $REPO_DIR && stow -D zsh"
echo "     Then restore from backup: $BACKUP_DIR"
echo

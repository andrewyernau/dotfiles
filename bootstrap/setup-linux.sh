#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Dotfiles repo: $REPO"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/powershell"

link_file() {
  local source="$1"
  local target="$2"

  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "Removing existing path: $target"
    rm -rf "$target"
  fi

  ln -s "$source" "$target"
  echo "Linked $target -> $source"
}

# Shared
link_file "$REPO/shared/starship.toml" "$HOME/.config/starship.toml"
link_file "$REPO/nvim" "$HOME/.config/nvim"

# Shells
link_file "$REPO/linux/bash/.bashrc" "$HOME/.bashrc"
# link_file "$REPO/linux/zsh/.zshrc" "$HOME/.zshrc"

# PowerShell profile on Linux (optional, only useful if pwsh is installed)
link_file "$REPO/linux/powershell/Microsoft.PowerShell_profile.ps1" \
  "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"

echo
echo "Bootstrap completed."
echo "Make sure these are installed: git, nvim, starship, rustup."
echo "Then open Neovim and run: :Pckr sync"

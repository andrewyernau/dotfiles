#!/usr/bin/env bash
set -e

REPO="$HOME/DOTFILES"

mkdir -p ~/.config/powershell
mkdir -p ~/.config

ln -sf "$REPO/linux/powershell/Microsoft.PowerShell_profile.ps1" ~/.config/powershell/Microsoft.PowerShell_profile.ps1
ln -sf "$REPO/shared/starship.toml" ~/.config/starship.toml

# Choose one:
ln -sf "$REPO/linux/bash/.bashrc" ~/.bashrc
# ln -sf "$REPO/linux/zsh/.zshrc" ~/.zshrc

echo "Linux dotfiles linked."

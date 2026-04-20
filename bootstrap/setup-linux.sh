#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Dotfiles repo: $REPO"

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/powershell"

APT_UPDATED=0

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
    return
  fi

  echo "Need root or sudo to install packages: $*" >&2
  return 1
}

has_any_command() {
  local command_name

  for command_name in "$@"; do
    if command -v "$command_name" >/dev/null 2>&1; then
      return 0
    fi
  done

  return 1
}

install_package() {
  local package_name="$1"
  local label="$2"

  shift 2

  if has_any_command "$@"; then
    echo "$label is already installed."
    return 0
  fi

  echo "Installing $label..."

  if command -v apt-get >/dev/null 2>&1; then
    if [ "$APT_UPDATED" -eq 0 ]; then
      run_as_root apt-get update || return 1
      APT_UPDATED=1
    fi
    run_as_root apt-get install -y "$package_name" || return 1
    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y "$package_name" || return 1
    return 0
  fi

  if command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -Sy --noconfirm "$package_name" || return 1
    return 0
  fi

  if command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive install "$package_name" || return 1
    return 0
  fi

  if command -v apk >/dev/null 2>&1; then
    run_as_root apk add "$package_name" || return 1
    return 0
  fi

  echo "Unsupported package manager. Install $label manually." >&2
  return 1
}

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

if ! install_package "fzf" "fzf" "fzf"; then
  echo "Skipping automatic fzf setup."
fi

if ! install_package "ripgrep" "ripgrep" "rg"; then
  echo "Skipping automatic ripgrep setup."
fi

if ! install_package "bat" "bat" "bat" "batcat"; then
  echo "Skipping automatic bat setup."
fi

echo
echo "Bootstrap completed."
echo "Make sure these are installed: git, nvim, starship, rustup."
echo "Then open Neovim and run: :Pckr sync"

#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STATIC_IP_CIDR="${STATIC_IP_CIDR:-}"
STATIC_INTERFACE="${STATIC_INTERFACE:-}"
STATIC_GATEWAY="${STATIC_GATEWAY:-}"
STATIC_DNS="${STATIC_DNS:-1.1.1.1,1.0.0.1}"

usage() {
  cat <<'EOF'
Usage: setup-linux.sh [network options]

  --static-ip ADDRESS/CIDR  Static IPv4 address (for example 192.168.1.50/24)
  --interface NAME         Network interface (auto-detected when omitted)
  --gateway ADDRESS        IPv4 gateway (auto-detected when omitted)
  --dns ADDRESSES          Comma-separated DNS servers (default: 1.1.1.1,1.0.0.1)
  --no-static-ip           Do not configure a static address or prompt for one
  -h, --help               Show this help

The same values can be supplied with STATIC_IP_CIDR, STATIC_INTERFACE,
STATIC_GATEWAY, and STATIC_DNS environment variables.
EOF
}

PROMPT_STATIC_IP=1
while [ "$#" -gt 0 ]; do
  case "$1" in
    --static-ip) STATIC_IP_CIDR="${2:?--static-ip requires a value}"; shift 2 ;;
    --interface) STATIC_INTERFACE="${2:?--interface requires a value}"; shift 2 ;;
    --gateway) STATIC_GATEWAY="${2:?--gateway requires a value}"; shift 2 ;;
    --dns) STATIC_DNS="${2:?--dns requires a value}"; shift 2 ;;
    --no-static-ip) PROMPT_STATIC_IP=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

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

configure_static_ip() {
  local connection

  if [ -z "$STATIC_IP_CIDR" ] && [ "$PROMPT_STATIC_IP" -eq 1 ] && [ -t 0 ]; then
    echo
    read -r -p "Static IPv4 with CIDR (leave empty to keep DHCP): " STATIC_IP_CIDR
  fi

  if [ -z "$STATIC_IP_CIDR" ]; then
    echo "Static IP setup skipped."
    return 0
  fi

  if ! [[ "$STATIC_IP_CIDR" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$ ]]; then
    echo "Invalid static IPv4/CIDR: $STATIC_IP_CIDR" >&2
    return 1
  fi

  if [ -z "$STATIC_INTERFACE" ]; then
    STATIC_INTERFACE="$(ip -4 route show default 2>/dev/null | awk 'NR == 1 { print $5 }')"
  fi
  if [ -z "$STATIC_GATEWAY" ]; then
    STATIC_GATEWAY="$(ip -4 route show default 2>/dev/null | awk 'NR == 1 { print $3 }')"
  fi
  if [ -z "$STATIC_INTERFACE" ] || [ -z "$STATIC_GATEWAY" ]; then
    echo "Could not detect interface or gateway; pass --interface and --gateway." >&2
    return 1
  fi

  echo "Configuring $STATIC_INTERFACE as $STATIC_IP_CIDR (gateway $STATIC_GATEWAY)..."
  if command -v nmcli >/dev/null 2>&1; then
    connection="$(nmcli -g GENERAL.CONNECTION device show "$STATIC_INTERFACE" | head -n 1)"
    if [ -z "$connection" ] || [ "$connection" = "--" ]; then
      echo "No active NetworkManager connection for $STATIC_INTERFACE." >&2
      return 1
    fi
    run_as_root nmcli connection modify "$connection" \
      ipv4.method manual \
      ipv4.addresses "$STATIC_IP_CIDR" \
      ipv4.gateway "$STATIC_GATEWAY" \
      ipv4.dns "$STATIC_DNS"
    run_as_root nmcli connection up "$connection"
    return 0
  fi

  echo "NetworkManager (nmcli) is required for automatic static IP setup." >&2
  echo "Install it or configure $STATIC_INTERFACE manually." >&2
  return 1
}

configure_fail2ban() {
  local config_source="$REPO/linux/fail2ban/jail.local"

  if ! install_package "fail2ban" "fail2ban" "fail2ban-client"; then
    echo "Fail2ban installation failed." >&2
    return 1
  fi

  run_as_root install -D -m 0644 "$config_source" /etc/fail2ban/jail.local

  if command -v systemctl >/dev/null 2>&1; then
    run_as_root systemctl enable --now fail2ban
    run_as_root systemctl restart fail2ban
  else
    echo "fail2ban installed; enable its service using your init system." >&2
  fi

  run_as_root fail2ban-client -t
  echo "Fail2ban configured: 5 failures in 60 seconds result in a permanent ban."
}

configure_docker() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "Docker and Docker Compose are already installed."
  else
    echo "Installing Docker and Docker Compose..."

    if command -v apt-get >/dev/null 2>&1; then
      if [ "$APT_UPDATED" -eq 0 ]; then
        run_as_root apt-get update
        APT_UPDATED=1
      fi
      if ! command -v docker >/dev/null 2>&1; then
        run_as_root apt-get install -y docker.io
      fi
      if apt-cache show docker-compose-v2 2>/dev/null | grep -q '^Package:'; then
        run_as_root apt-get install -y docker-compose-v2
      elif apt-cache show docker-compose-plugin 2>/dev/null | grep -q '^Package:'; then
        run_as_root apt-get install -y docker-compose-plugin
      else
        echo "No Docker Compose v2 package was found in the configured APT repositories." >&2
        return 1
      fi
    elif command -v dnf >/dev/null 2>&1; then
      run_as_root dnf install -y docker docker-compose-plugin
    elif command -v pacman >/dev/null 2>&1; then
      run_as_root pacman -Sy --noconfirm docker docker-compose
    elif command -v zypper >/dev/null 2>&1; then
      run_as_root zypper --non-interactive install docker docker-compose
    elif command -v apk >/dev/null 2>&1; then
      run_as_root apk add docker docker-cli-compose
    else
      echo "Unsupported package manager. Install Docker and Docker Compose manually." >&2
      return 1
    fi
  fi

  if command -v systemctl >/dev/null 2>&1; then
    run_as_root systemctl enable --now docker
  else
    echo "Docker installed; enable its service using your init system." >&2
  fi

  docker compose version
}

configure_zsh() {
  local p10k_dir="${XDG_DATA_HOME:-$HOME/.local/share}/powerlevel10k"

  if ! install_package "zsh" "Zsh" "zsh"; then
    echo "Zsh installation failed." >&2
    return 1
  fi

  if [ ! -d "$p10k_dir/.git" ]; then
    if [ -e "$p10k_dir" ]; then
      echo "Cannot install Powerlevel10k: $p10k_dir already exists and is not a Git checkout." >&2
      return 1
    fi
    mkdir -p "$(dirname "$p10k_dir")"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
  else
    echo "Powerlevel10k is already installed."
  fi
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [ "${SHELL:-}" = "$zsh_path" ]; then
    echo "Zsh is already the default shell."
    return 0
  fi

  if [ -t 0 ]; then
    printf "Set Zsh as the default shell for %s? [Y/n] " "$(id -un)"
    read -r reply
    case "$reply" in
      [nN]|[nN][oO]) echo "Default shell unchanged."; return 0 ;;
    esac
    chsh -s "$zsh_path"
    echo "Default shell changed to Zsh. The current terminal is still running the old shell."
    echo "Reconnect your SSH session or run 'exec $zsh_path -l' to apply it now."
  else
    echo "Run 'chsh -s $zsh_path' to make Zsh your default shell."
  fi
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

link_file "$REPO/nvim" "$HOME/.config/nvim"

# Shells
link_file "$REPO/linux/bash/.bashrc" "$HOME/.bashrc"
configure_zsh
link_file "$REPO/linux/zsh/.zshrc" "$HOME/.zshrc"
link_file "$REPO/linux/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
set_default_shell

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

configure_fail2ban
configure_docker
configure_static_ip

echo
echo "Bootstrap completed."
echo "Make sure these are installed: git, nvim, rustup."
echo "Then open Neovim and run: :Pckr sync"

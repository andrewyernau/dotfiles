#!/usr/bin/env bash
# Ubuntu/WSL shell-only bootstrap. Run as your regular user, not with sudo.
set -euo pipefail
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=1
DEFAULT_SHELL=1
DRY_RUN=0
usage() {
  cat <<'HELP'
Usage: bash bootstrap/setup-wsl.sh [options]
  --dry-run           Show the plan without making changes
  --no-packages       Use installed dependencies; do not run apt
  --no-default-shell  Link configuration without changing the login shell
  -h, --help          Show help
Installs Zsh, suggestions, highlighting, fzf, rg, bat, and pinned Powerlevel10k.
Backs up replaced files. Does not configure networking, Docker, or other services.
HELP
}
for option in "$@"; do
  case "$option" in
    --dry-run) DRY_RUN=1 ;;
    --no-packages) PACKAGES=0 ;;
    --no-default-shell) DEFAULT_SHELL=0 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$option" >&2; exit 2 ;;
  esac
done
P10K_REV=d05a1b00f9a61f9578bf9dc19b8451942dde8734
P10K_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/powerlevel10k"
BACKUP="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/backups/$(date +%Y%m%d-%H%M%S)-$$"
links=(linux/zsh/.zshrc linux/zsh/.zprofile linux/zsh/.p10k.zsh linux/tmux/.tmux.conf)
targets=("$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.p10k.zsh" "$HOME/.tmux.conf")
if (( DRY_RUN )); then
  printf 'Repository: %s\nBackup directory if needed: %s\n' "$REPO" "$BACKUP"
  printf 'APT installation: %s; change login shell: %s\n' "$PACKAGES" "$DEFAULT_SHELL"
  printf 'Powerlevel10k: %s at %s (existing installs preserved)\n' "$P10K_DIR" "$P10K_REV"
  for i in "${!links[@]}"; do printf 'Link %s -> %s/%s\n' "${targets[$i]}" "$REPO" "${links[$i]}"; done
  exit 0
fi
if (( EUID == 0 )); then
  echo 'Run as your regular WSL user; the script uses sudo only for apt.' >&2
  exit 1
fi
if (( PACKAGES )); then
  [[ -r /etc/os-release ]] || { echo 'Cannot identify OS.' >&2; exit 1; }
  . /etc/os-release
  [[ "$ID" == ubuntu || "$ID" == debian ]] || { echo 'This installer supports Ubuntu/Debian; use --no-packages elsewhere.' >&2; exit 1; }
  sudo apt-get update
  sudo apt-get install -y zsh zsh-autosuggestions zsh-syntax-highlighting tmux fzf ripgrep bat git ca-certificates
fi
for dependency in zsh git fzf tmux; do
  command -v "$dependency" >/dev/null || { printf 'Missing dependency: %s\n' "$dependency" >&2; exit 1; }
done
for config in .zshrc .zprofile .p10k.zsh; do
  zsh -n "$REPO/linux/zsh/$config"
done
if [[ ! -e "$P10K_DIR" && ! -L "$P10K_DIR" ]]; then
  mkdir -p "$(dirname -- "$P10K_DIR")"
  theme_tmp=$(mktemp -d "${P10K_DIR}.install.XXXXXX")
  trap 'rm -rf -- "$theme_tmp"' EXIT
  git -C "$theme_tmp" init -q
  git -C "$theme_tmp" remote add origin https://github.com/romkatv/powerlevel10k.git
  git -C "$theme_tmp" fetch --depth=1 origin "$P10K_REV"
  git -C "$theme_tmp" checkout -q --detach FETCH_HEAD
  mv -- "$theme_tmp" "$P10K_DIR"
  trap - EXIT
elif [[ ! -r "$P10K_DIR/powerlevel10k.zsh-theme" ]]; then
  printf 'Existing path is not Powerlevel10k: %s\n' "$P10K_DIR" >&2
  exit 1
fi
for i in "${!links[@]}"; do
  source_file="$REPO/${links[$i]}"
  target="${targets[$i]}"
  [[ -L "$target" && "$(readlink -- "$target")" == "$source_file" ]] && continue
  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP"
    mv -- "$target" "$BACKUP/$(basename -- "$target")"
  fi
  ln -s -- "$source_file" "$target"
  printf 'Linked %s\n' "$target"
done
if (( DEFAULT_SHELL )); then
  zsh_path="$(command -v zsh)"
  login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
  if [[ "$login_shell" != "$zsh_path" ]]; then
    chsh -s "$zsh_path"
  fi
fi
printf '\nSetup complete. Start Zsh with: exec zsh -l\n'
[[ ! -d "$BACKUP" ]] || printf 'Previous configuration: %s\n' "$BACKUP"
printf 'Bash configuration was preserved. Existing tmux sessions keep their running shell.\n'

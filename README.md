# dotfiles

Cross-platform dotfiles for Windows and Linux.

The Neovim configuration is shared across both platforms, while OS-specific settings live under `windows/` and `linux/`.

## Repository structure

```text
.
├── bootstrap/
├── linux/
├── nvim/
└── windows/
```

## Installation

Clone the repository and run the bootstrap script for your platform.

### Windows

```powershell
git clone <repo-url> $HOME\dotfiles
cd $HOME\dotfiles
.\bootstrap\setup-windows.ps1
```

### Linux

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
chmod +x ./bootstrap/setup-linux.sh
./bootstrap/setup-linux.sh
```

The Linux bootstrap prompts for an optional static IPv4 address. It detects the
active interface and gateway and configures its NetworkManager connection. For
an unattended setup, pass the values explicitly:

```bash
./bootstrap/setup-linux.sh \
  --static-ip 192.168.1.50/24 \
  --interface enp3s0 \
  --gateway 192.168.1.1 \
  --dns 1.1.1.1,1.0.0.1
```

Use `--no-static-ip` to keep DHCP without an interactive prompt. Changing the
address can interrupt a remote SSH session, so run it from a local console when
possible and reserve the chosen address in the router's DHCP configuration.

## What the bootstrap scripts do
The bootstrap scripts:

- install `fzf`, `ripgrep`, and `bat` automatically when a supported package manager is available
- install Zsh and Powerlevel10k, link their configuration, and offer to make Zsh the default shell
- install and enable fail2ban for SSH (5 failures in 60 seconds cause a permanent ban)
- install Docker Engine and Docker Compose v2 and enable the Docker service
- optionally configure a static IPv4 address through NetworkManager on Linux
- link the Neovim configuration into the correct path
- link shell-specific configuration files
- link the PowerShell profile
- prepare the local configuration directories

## Requirements

Some external dependencies must already be installed:

- git
- Neovim
- Zsh and Powerlevel10k on Linux (installed by the bootstrap)
- Rust toolchain (rustup)
- Rust components: rust-analyzer, rustfmt, clippy

`fzf`, `ripgrep`, and `bat` are installed by the bootstrap scripts when `winget` is available on Windows or a supported package manager is available on Linux.
On some Debian/Ubuntu-based systems, `bat` is exposed as `batcat`.

On Linux, Docker commands require `sudo` by default. The bootstrap deliberately
does not add the current user to the `docker` group because membership grants
root-equivalent access to the machine.

Optional:

- CodeLLDB for Rust debugging
- PowerShell 7 on Linux (better don't, just in case you're using WSL)

## Linux terminal

The default Linux setup uses Zsh with a Pure-inspired Powerlevel10k theme. Its
two-line prompt keeps the path and asynchronous Git state above a clean command
line, and only shows `user@host` over SSH. It uses ASCII characters exclusively,
so no patched font, icons, or emoji are required.

The bootstrap asks before changing the login shell. Open a new terminal after
the change, or start it immediately with `exec zsh`.

## Neovim

After bootstrapping, open Neovim and install or sync plugins:

```vim
:Pckr sync
```
[!Tip] Some useful Pckr commands you might need

```vim
:Pckr install
:Pckr sync
:Pckr update
:Pckr clean
:Pckr status
```
## LSP

### Rust setup

Rust support in Neovim depends on external tooling being installed on the system.
Install rust components with:
```bash
rustup component add rust-analyzer rustfmt clippy
```

### Debugging

For debugging Rust inside Neovim, install CodeLLDB separately.

---

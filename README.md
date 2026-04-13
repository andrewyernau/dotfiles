# dotfiles

Cross-platform dotfiles for Windows and Linux.

The Neovim configuration is shared across both platforms, while OS-specific settings live under `windows/` and `linux/`.

## Repository structure

```text
.
├── bootstrap/
├── linux/
├── nvim/
├── shared/
└── windows/

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
## What the bootstrap scripts do
The bootstrap scripts:

- link the Neovim configuration into the correct path
- link the shared Starship prompt configuration
- link shell-specific configuration files
- link the PowerShell profile
- prepare the local configuration directories

## Requirements

Some external dependencies must already be installed:

- git
- Neovim
- Starship
- Rust toolchain (rustup)
- Rust components: rust-analyzer, rustfmt, clippy

Optional:

- CodeLLDB for Rust debugging
- PowerShell 7 on Linux (better don't, just in case you're using WSL)

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

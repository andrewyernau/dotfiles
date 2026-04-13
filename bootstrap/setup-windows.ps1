$repo = "D:\DOTFILES"

# Ensure PowerShell profile path exists
$profileDir = Split-Path -Parent $PROFILE
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

# Symlink PowerShell profile
New-Item -ItemType SymbolicLink `
  -Path $PROFILE `
  -Target "$repo\windows\powershell\Microsoft.PowerShell_profile.ps1" `
  -Force | Out-Null

# Starship config
$configDir = "$HOME\.config"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

New-Item -ItemType SymbolicLink `
  -Path "$configDir\starship.toml" `
  -Target "$repo\shared\starship.toml" `
  -Force | Out-Null

Write-Host "Windows dotfiles linked."

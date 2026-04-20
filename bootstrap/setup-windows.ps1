$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$userConfig = Join-Path $HOME ".config"
$nvimConfig = Join-Path $env:LOCALAPPDATA "nvim"
$starshipConfig = Join-Path $userConfig "starship.toml"
$psProfilePath = $PROFILE.CurrentUserCurrentHost
$psProfileDir = Split-Path -Parent $psProfilePath

Write-Host "Dotfiles repo: $repo"

New-Item -ItemType Directory -Force -Path $userConfig | Out-Null
New-Item -ItemType Directory -Force -Path $psProfileDir | Out-Null

function Test-CommandAvailable {
    param([string]$Name)

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-WithWinget {
    param(
        [string]$CommandName,
        [string]$PackageId,
        [string]$Label
    )

    if (Test-CommandAvailable -Name $CommandName) {
        Write-Host "$Label is already installed."
        return
    }

    if (Test-CommandAvailable -Name "winget") {
        Write-Host "Installing $Label with winget..."
        & winget install --id $PackageId -e --accept-package-agreements --accept-source-agreements

        if ($LASTEXITCODE -eq 0) {
            return
        }

        Write-Warning "winget could not install $Label automatically. Install it manually and rerun the bootstrap if needed."
        return
    }

    Write-Warning "winget is not available. Install $Label manually."
}

function Remove-PathIfExists {
    param([string]$Path)

    if (Test-Path $Path) {
        Write-Host "Removing existing path: $Path"
        Remove-Item $Path -Recurse -Force
    }
}

function New-Symlink {
    param(
        [string]$LinkPath,
        [string]$TargetPath
    )

    Remove-PathIfExists -Path $LinkPath
    New-Item -ItemType SymbolicLink -Path $LinkPath -Target $TargetPath | Out-Null
}

Install-WithWinget -CommandName "fzf" -PackageId "junegunn.fzf" -Label "fzf"
Install-WithWinget -CommandName "rg" -PackageId "BurntSushi.ripgrep.MSVC" -Label "ripgrep"
Install-WithWinget -CommandName "bat" -PackageId "sharkdp.bat" -Label "bat"

Write-Host "Linking PowerShell profile..."
New-Symlink `
    -LinkPath $psProfilePath `
    -TargetPath (Join-Path $repo "windows\powershell\Microsoft.PowerShell_profile.ps1")

Write-Host "Linking Starship config..."
New-Symlink `
    -LinkPath $starshipConfig `
    -TargetPath (Join-Path $repo "shared\starship.toml")

Write-Host "Linking Neovim config..."
if (Test-Path $nvimConfig) {
    Write-Host "Removing existing Neovim config: $nvimConfig"
    Remove-Item $nvimConfig -Recurse -Force
}
cmd /c "mklink /J `"$nvimConfig`" `"$repo\nvim`"" | Out-Host

Write-Host ""
Write-Host "Bootstrap completed."
Write-Host "Make sure these are installed: git, nvim, starship, rustup."
Write-Host "Then open Neovim and run: :Pckr sync"

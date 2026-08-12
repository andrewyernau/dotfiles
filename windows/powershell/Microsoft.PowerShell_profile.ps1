# Basic aliases
Set-Alias ll Get-ChildItem

function grep {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Pattern,
        [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
        [string[]]$Path
    )

    if ($null -ne $Path -and $Path.Count -gt 0) {
        Select-String -Pattern $Pattern -Path $Path
        return
    }

    $input | Select-String -Pattern $Pattern
}

# Better listing
function la {
    Get-ChildItem -Force
}

# Reload PATH from the current machine/user environment variables.
function reloadenv {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [Environment]::GetEnvironmentVariable("Path", "User")
}

Set-Alias reload reloadenv

# Git shortcuts
function gs { git status }
function ga { git add . }
function gc { param([string]$m) git commit -m $m }
function gp { git push }
function gd { git diff }

# Basic aliases
Set-Alias ll Get-ChildItem
Set-Alias grep Select-String

# Better listing
function la {
    Get-ChildItem -Force
}

# Git shortcuts
function gs { git status }
function ga { git add . }
function gc { param([string]$m) git commit -m $m }
function gp { git push }
function gd { git diff } 

# Prompt
Invoke-Expression (&starship init powershell)

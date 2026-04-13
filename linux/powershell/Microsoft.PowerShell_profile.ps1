Set-Alias ll Get-ChildItem
Set-Alias grep Select-String

function la {
    Get-ChildItem -Force
}

function gs { git status }
function ga { git add . }
function gc { param([string]$m) git commit -m $m }
function gp { git push }
function gd { git diff }

Invoke-Expression (&starship init powershell)

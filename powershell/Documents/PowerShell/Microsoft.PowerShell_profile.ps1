# oh-my-posh prompt; the theme lives next to this file in the repo, so resolve
# through the symlink that $PROFILE normally is
$profileTarget = (Get-Item $PROFILE -ErrorAction SilentlyContinue).Target
$profileDir = if ($profileTarget) { Split-Path $profileTarget } else { $PSScriptRoot }
$ompTheme = Join-Path $profileDir 'ohmyposh.json'
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path $ompTheme)) {
    oh-my-posh init pwsh --config $ompTheme | Invoke-Expression
}

# zoxide: `z` jumps to frecent directories, `zi` is interactive
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd z | Out-String) })
}

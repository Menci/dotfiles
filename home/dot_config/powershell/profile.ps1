$localBin = Join-Path $HOME '.local\bin'
if ($localBin -notin ($env:PATH -split [IO.Path]::PathSeparator)) {
    $env:PATH = $localBin + [IO.Path]::PathSeparator + $env:PATH
}

fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)
Set-PSReadLineKeyHandler -Key 'Alt+Backspace' -Function BackwardDeleteWord

function Resolve-ApplicationPath {
    param([Parameter(Mandatory)][string]$Name)
    # PATH may hold several executables of the same name (e.g. both the Windows
    # OpenSSH scp and Git's scp); take the first, matching bare-name resolution.
    (Get-Command $Name -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
}

function scp {
    & (Resolve-ApplicationPath scp) -O @args
}

function codex {
    & (Resolve-ApplicationPath codex) --sandbox danger-full-access --dangerously-bypass-approvals-and-sandbox @args
}

function claude {
    & (Resolve-ApplicationPath claude) --disallowedTools 'EnterPlanMode,AskUserQuestion' --dangerously-skip-permissions @args
}

$localProfile = Join-Path $HOME '.config\powershell\local.ps1'
if (Test-Path -LiteralPath $localProfile -PathType Leaf) {
    . $localProfile
}

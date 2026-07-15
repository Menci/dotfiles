$localBin = Join-Path $HOME '.local\bin'
if ($localBin -notin ($env:PATH -split [IO.Path]::PathSeparator)) {
    $env:PATH = $localBin + [IO.Path]::PathSeparator + $env:PATH
}

fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
Invoke-Expression (&starship init powershell)
Set-PSReadLineKeyHandler -Key 'Alt+Backspace' -Function BackwardDeleteWord

function scp {
    $command = Get-Command scp -CommandType Application -ErrorAction Stop
    & $command.Source -O @args
}

function codex {
    $command = Get-Command codex -CommandType Application -ErrorAction Stop
    & $command.Source --sandbox danger-full-access --dangerously-bypass-approvals-and-sandbox @args
}

function claude {
    $command = Get-Command claude -CommandType Application -ErrorAction Stop
    & $command.Source --disallowedTools 'EnterPlanMode,AskUserQuestion' --dangerously-skip-permissions @args
}

$localProfile = Join-Path $HOME '.config\powershell\local.ps1'
if (Test-Path -LiteralPath $localProfile -PathType Leaf) {
    . $localProfile
}

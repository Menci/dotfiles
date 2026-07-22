$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = 'https://github.com/Menci/dotfiles.git'
$sourceDir = Join-Path $HOME 'Projects\dotfiles'
$binDir = Join-Path $HOME '.local\bin'
$installerSource = Invoke-RestMethod `
    -UseBasicParsing `
    -Uri 'https://get.chezmoi.io/ps1' `
    -ErrorAction Stop
$installer = [scriptblock]::Create($installerSource)

& $installer -BinDir $binDir

$chezmoi = Join-Path $binDir 'chezmoi.exe'

# `chezmoi init` only clones when the working tree is absent; against an
# existing source repo it neither fetches nor pulls, so re-running the
# bootstrap would keep applying a stale checkout. Branch on the repo's
# presence: `update` pulls (git pull --autostash --rebase) then applies,
# while `init --apply` handles the fresh-machine clone.
if (Test-Path -LiteralPath (Join-Path $sourceDir '.git')) {
    & $chezmoi --source $sourceDir update
} else {
    & $chezmoi --source $sourceDir init --apply $repo
}

if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    throw "chezmoi exited with code $LASTEXITCODE."
}

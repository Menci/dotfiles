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

& $installer `
    -BinDir $binDir `
    -ChezmoiArgs @('--source', $sourceDir, 'init', '--apply', $repo)

if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    throw "chezmoi exited with code $LASTEXITCODE."
}

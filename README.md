# dotfiles

Personal Bash, PowerShell, and agent configuration managed by chezmoi. The
bootstrap installs Starship, fnm, the current Node.js LTS release, shared agent
skills, and optional agent integrations.

## Bootstrap

On macOS, Linux, or WSL:

```sh
curl -fsSL https://raw.githubusercontent.com/Menci/dotfiles/main/install.sh | sh
```

On Windows:

```powershell
irm https://raw.githubusercontent.com/Menci/dotfiles/main/install.ps1 | iex
```

Linux bootstrap installs `curl` and `unzip` through the distribution package
manager when fnm needs them. On WSL, managed shell sessions and installation
scripts remove Windows-backed directories from `PATH`, so Linux automation
does not invoke Windows-side tools. Add an explicit path back from
`~/.config/shell/local.sh` when a particular Windows command is intentionally
shared with WSL.

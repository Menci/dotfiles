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

## Agent configuration

Shared skills live in `~/.agents/skills`; Claude uses the `~/.claude/skills`
symlink.

`home/.chezmoidata/agent-preferences.json` contains portable Claude and Codex
preferences: interface behavior, reasoning effort, execution preferences,
plugin selections, and Claude session limits and marketplace registrations.
The modifier templates merge these preferences into application-owned files.
Codex assignments already carrying the intended values retain their formatting;
unmanaged assignments and comments remain intact. Claude merges named entries
inside its environment, plugin, and marketplace maps so additional local entries
survive.

Provider credentials and model routing, project trust, installed-tool paths,
marketplace installation paths, and generated onboarding state remain local.
Capture live edits by updating the preference data or the corresponding managed
skill, then validate modifier output in an isolated destination with scripts
excluded before applying it to another machine.

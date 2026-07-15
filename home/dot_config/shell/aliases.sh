#!/bin/sh

export PATH="$HOME/.local/bin:$PATH"

alias grep='grep --color=auto'
alias ls='ls --color=auto'

alias scp='scp -O'
alias codex='codex --sandbox danger-full-access --dangerously-bypass-approvals-and-sandbox'
alias claude='claude --disallowedTools EnterPlanMode,AskUserQuestion --dangerously-skip-permissions'

case "$(uname -s)" in
  Darwin) . "$HOME/.config/shell/aliases.darwin.sh" ;;
  Linux) . "$HOME/.config/shell/aliases.linux.sh" ;;
esac

#!/usr/bin/env bash

if [ "${_DOTFILES_BASHRC_LOADED:-}" != 1 ]; then
  _DOTFILES_BASHRC_LOADED=1

  . "$HOME/.config/shell/env.sh"
  fnm_env="$(fnm env --use-on-cd --shell bash)"
  eval "$fnm_env"
  unset fnm_env
  . "$HOME/.config/shell/aliases.sh"

  eval "$(starship init bash)"
fi

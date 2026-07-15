#!/bin/sh

if [ -n "${BASH_VERSION:-}" ] && [ "${_DOTFILES_BASHRC_LOADED:-}" != 1 ]; then
  case $- in
    *i*) . "$HOME/.bashrc" ;;
  esac
fi

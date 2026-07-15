#!/bin/sh
set -eu

repo='https://github.com/Menci/dotfiles.git'
source_dir="$HOME/Projects/dotfiles"
bin_dir="$HOME/.local/bin"
installer="$(mktemp)"

trap 'rm -f "$installer"' EXIT
trap 'exit 1' HUP INT TERM

curl --fail --show-error --silent --location \
  https://get.chezmoi.io \
  --output "$installer"

sh "$installer" -b "$bin_dir" -- \
  --source "$source_dir" \
  init --apply "$repo"

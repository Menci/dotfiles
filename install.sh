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

sh "$installer" -b "$bin_dir"

chezmoi="$bin_dir/chezmoi"

# `chezmoi init` only clones when the working tree is absent; against an
# existing source repo it neither fetches nor pulls, so re-running the
# bootstrap would keep applying a stale checkout. Branch on the repo's
# presence: `update` pulls (git pull --autostash --rebase) then applies,
# while `init --apply` handles the fresh-machine clone.
if [ -d "$source_dir/.git" ]; then
  "$chezmoi" --source "$source_dir" update
else
  "$chezmoi" --source "$source_dir" init --apply "$repo"
fi

#!/usr/bin/env bash

TMUX_FZF_OPTIONS="$TMUX_FZF_OPTIONS --header='Select a command.'"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

target_origin=$(tmux list-commands)
target=$(printf "$target_origin" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS" | cut -d ' ' -f 1)

[[ -z "$target" ]] && exit
tmux command-prompt -I "$target"

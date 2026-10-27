#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

OPTS="--delimiter $'\\t' --with-nth=1 --accept-nth=2.."

target=$(printf '%s' "$TMUX_FZF_MENU" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS")

[[ -z "$target" ]] && exit

tmux -c "$target"

#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

OPTS="--delimiter $'\\t' --with-nth=1 --accept-nth=2.."

target=$(printf '%s' "$TMUX_FZF_MENU" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS")

[[ -z "$target" ]] && exit

if [[ -z "$TMUX_FZF_MENU_POPUP" ]]; then
  tmux -c "$target"
else
  tmux popup -xC -yC -w"${TMUX_FZF_MENU_POPUP_WIDTH:-50%}" -h"${TMUX_FZF_MENU_POPUP_HEIGHT:-50%}" "$target" || true
fi

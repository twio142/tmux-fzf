#!/usr/bin/env bash

OPTS="--nth=1,2 --accept-nth=1 --header='${BOLD}^H${OFF} help / ${BOLD}^Y${OFF} yank' \
  --bind='ctrl-h:print(help)+accept' \
  --bind='ctrl-y:execute-silent(printf {1} | tmux load-buffer -)' \
  --preview-window=wrap \
  --preview=\"l=\\\$(MANWIDTH=\\\$FZF_PREVIEW_COLUMNS man tmux | col -bx | grep -En '^     {1}($| \\[)' | cut -d: -f1); [ -z \\\${l} ] || MANWIDTH=\\\$FZF_PREVIEW_COLUMNS man tmux | col -bx | bat -l man -r \\\${l}: -H \\\${l}\""
TMUX_FZF_OPTIONS="$TMUX_FZF_OPTIONS"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

target_origin=$(tmux list-commands -F "#{p20:command_list_name} ${ITALIC}#{p10:command_list_alias}${OFF} ${DIM}#{command_list_usage}${OFF}")
target=$(printf "$target_origin" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS")

if [[ -z "$target" ]]; then
  exit 0
elif [[ "$target" == help* ]]; then
  target=$(echo "$target" | tail -n1)
  line=$(tmux list-commands -F '#{command_list_name} #{s/(\[|\])/\\\1/g:#{=10:command_list_usage}}' | awk -v t=$target '$1 == t {print $0}')
  MANPAGER="sh -c \"col -bx | bat -l man --paging always | less -R '+/${line/% }.*'\""
  tmux splitw -v -e MANPAGER="$MANPAGER" man tmux
else
  tmux command-prompt -I "$target"
fi

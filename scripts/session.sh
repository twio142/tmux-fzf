#!/usr/bin/env bash

SCPT="${BASH_SOURCE[0]}"
CURRENT_DIR="$(cd "$(dirname "$SCPT")" && pwd)"
source "$CURRENT_DIR/.envs"

if [[ -z "$TMUX_FZF_SESSION_FORMAT" ]]; then
  sessions=$(tmux list-sessions)
  reload="tmux ls"
else
  sessions=$(tmux list-sessions -F "#S: $TMUX_FZF_SESSION_FORMAT")
  reload="tmux ls -F \\\"#S: \$TMUX_FZF_SESSION_FORMAT\\\""
fi

OPTS="--header='${BOLD}^D${OFF} detach / ${BOLD}^X${OFF} kill / ${BOLD}^N${OFF} new / ${BOLD}^R${OFF} rename' \
--delimiter=':' \
--bind=\"ctrl-d:execute(echo {+1} | tr ' ' '$NL' | xargs -I _ tmux detach -s '_')+reload($reload)\" \
--bind=\"ctrl-x:execute(echo {+1} | tr ' ' '$NL' | xargs -I _ tmux kill-session -t '_')+reload($reload)\" \
--bind=\"ctrl-n:execute(tmux new -d \\; switchc -n)+reload($reload)\" \
--bind=\"ctrl-r:print(rename)+accept\" \
--bind='return:execute(tmux switchc -t {1})+abort'"

current=$(tmux display-message -p '#S: ')
output=$(printf "$sessions" | sed "/^$current/ s/$/ /" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS $TMUX_FZF_PREVIEW_OPTIONS")

[ -z "$output" ] && exit 0
action=$(echo "$output" | head -n1)
output=$(echo "$output" | sed '1d')
if [[ "$action" == "rename" ]]; then
  echo "$output" | sed 's/: .*//' | while read sess; do
    tmux command-prompt -p 'Rename session:' -I "$sess" 'rename-session -- "%%"'
  done
fi

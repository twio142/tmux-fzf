#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

current_window_origin=$(tmux display-message -p '#S:#I: #{window_name}')
current_window=$(tmux display-message -p '#S:#I:')

if [[ -z  "$TMUX_FZF_WINDOW_FILTER" ]]; then
  window_filter="-a"
else
  window_filter="-f \"$TMUX_FZF_WINDOW_FILTER\""
fi

if [[ -z "$TMUX_FZF_WINDOW_FORMAT" ]]; then
  windows=$(tmux list-windows $window_filter | sed -E "s/^([^ ]+)/${YELLOW}\1${OFF}/")
  reload="tmux list-windows $window_filter | sed -E \\\"s/^([^ ]+)/${YELLOW}\\\\1${OFF}/\\\""
else
  windows=$(tmux list-windows $window_filter -F "#S:#I: $TMUX_FZF_WINDOW_FORMAT #{?#{==:#S:#I,$(tmux display -p '#S:#I')}, ,}" | sed -E "s/^([^ ]+)/${YELLOW}\1${OFF}/")
  reload="tmux list-windows $window_filter -F \\\"#S:#I: \$TMUX_FZF_WINDOW_FORMAT #{?#{==:#S:#I,\\\$(tmux display -p '#S:#I')}, ,}\\\" | sed -E \\\"s/^([^ ]+)/${YELLOW}\\\\1${OFF}/\\\""
fi

OPTS="--header='${BOLD}^X${OFF} kill / ${BOLD}^R${OFF} rename / ${BOLD}^V${OFF} move / ${BOLD}^L${OFF} link' \
--delimiter=': ' \
--bind=\"ctrl-x:execute(echo {+1} | tr ' ' '$NL' | xargs -I _ tmux unlink-window -k -t '_')+reload($reload)\" \
--bind='ctrl-r:print(rename)+accept' \
--bind='ctrl-v:print(move)+accept' \
--bind='ctrl-l:print(link)+accept' \
--bind='return:execute(tmux switchc -t {1})+abort'"

output=$(printf "$windows" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS $TMUX_FZF_PREVIEW_OPTIONS --ansi")

[ -z "$output" ] && exit 0
action=$(echo "$output" | head -n1)
output=$(echo "$output" | sed '1d')
case "$action" in
  rename)
    echo "$output" | sed 's/: .*//' | while read win; do
      w=$(tmux lsp -t "$win" -F "#W" | head -n1)
      tmux command-prompt -p 'Rename win:' -I "$w" "rename-window -t '$win' -- \"%%\""
    done;;
  move)
    # move window to another session
    sess=$(tmux ls -F "#S" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS --header 'Move to session' $TMUX_FZF_PREVIEW_OPTIONS")
    [[ -z "$sess" ]] && exit
    echo "$output" | sed 's/: .*//' | while read win; do
      tmux move-window -s "$win" -t "$sess"
    done;;
  link)
    # link window to a window from another session
    tar=$(tmux display -p '#S:#I')
    src=$(echo "$output" | head -n1 | sed 's/: .*//')
    [[ "${src/:*}" == "${tar/:*}" ]] && exit
    tmux link-window -a -s "$src" -t "$tar" ;;
esac

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
  windows=$(tmux list-windows $window_filter)
  reload="tmux list-windows $window_filter"
else
  windows=$(tmux list-windows $window_filter -F "${YELLOW}#S:#I:${OFF} $TMUX_FZF_WINDOW_FORMAT #{?#{==:#S:#I,$(tmux display -p '#S:#I')}, ,}")
  reload="tmux list-windows $window_filter -F \\\"${YELLOW}#S:#I:${OFF} \$TMUX_FZF_WINDOW_FORMAT #{?#{==:#S:#I,\\\$(tmux display -p '#S:#I')}, ,}\\\""
fi

OPTS="--header='${BOLD}^X${OFF} kill / ${BOLD}^R${OFF} rename / ${BOLD}^V${OFF} move / ${BOLD}^L${OFF} link' \
--preview-label=' Windows ' --preview-label-pos bottom \
--delimiter=': ' \
--bind=\"ctrl-x:execute(echo {+1} | tr ' ' '$NL' | xargs -I _ tmux unlink-window -k -t '_')+reload($reload)\" \
--bind='ctrl-r:print(rename)+accept' \
--bind='ctrl-v:print(move)+accept' \
--bind='ctrl-l:print(link)+accept' \
--bind='return:execute(tmux switchc -t {1})+abort'"

output=$(printf "$windows" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS $TMUX_FZF_PREVIEW_OPTIONS")

[ -z "$output" ] && exit 0
{ read -r action; output=$(cat); } <<< "$output"
case "$action" in
  rename)
    echo "$output" | sed 's/: .*//' | while read win; do
      w=$(tmux lsp -t "$win" -F "#W" | head -n1)
      tmux command-prompt -p 'Rename win:' -I "$w" "rename-window -t '$win' -- \"%%\""
    done;;
  move)
    # move window to another session
    sess_opts="--header='${BOLD}⌥N${OFF} new session' \
--preview-label=' Move to session ' --preview-label-pos bottom \
--print-query \
--bind='alt-n:print(new)+accept'"
    sess=$(tmux ls -F "#S:" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $sess_opts $TMUX_FZF_PREVIEW_OPTIONS")
    [[ -z "$sess" ]] && exit
    { read -r query; read -r sess; } <<< "$sess"
    if [[ "$sess" == "new" ]]; then
      # create a new session, named after the query if any
      if [[ -z "$query" ]]; then
        placeholder=$(tmux new -d -P -F "#{session_id}:#{window_id}")
      elif tmux has -t "=$query" 2>/dev/null; then
        # the name is taken, move into that session instead
        sess="$query:"
      else
        placeholder=$(tmux new -d -P -F "#{session_id}:#{window_id}" -s "$query" 2>/dev/null)
      fi
      if [[ -n "$placeholder" ]]; then
        # ids, not names: an auto-named session gets renumbered as windows move in
        sess="${placeholder%%:*}:"
        placeholder="${placeholder#*:}"
      fi
      [[ "$sess" == "new" ]] && exit
    fi
    [[ -z "$sess" ]] && exit
    echo "$output" | sed 's/: .*//' | while read win; do
      tmux move-window -s "$win" -t "$sess"
    done
    # drop the new session's initial window, unless nothing was moved into it
    if [[ -n "$placeholder" ]] && [[ $(tmux list-windows -t "$sess" | wc -l) -gt 1 ]]; then
      tmux kill-window -t "$placeholder"
    fi;;
  link)
    # link window to a window from another session
    tar=$(tmux display -p '#S:#I')
    src=$(echo "$output" | head -n1 | sed 's/: .*//')
    [[ "${src/:*}" == "${tar/:*}" ]] && exit
    tmux link-window -a -s "$src" -t "$tar" ;;
esac

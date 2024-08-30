#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

current_pane_origin=$(tmux display-message -p '#S:#{window_index}.#{pane_index}: #{window_name}')
current_pane=$(tmux display-message -p '#S:#{window_index}.#{pane_index}')

if [[ -z "$TMUX_FZF_PANE_FORMAT" ]]; then
  panes=$(tmux list-panes -a -F "#S:#{window_index}.#{pane_index}: [#{window_name}:#{pane_title}] #{pane_current_command}  [#{pane_width}x#{pane_height}] [history #{history_size}/#{history_limit}, #{history_bytes} bytes] #{?pane_active,[active],[inactive]}")
  reload="tmux list-panes -a -F \\\"#S:#{window_index}.#{pane_index}: [#{window_name}:#{pane_title}] #{pane_current_command}  [#{pane_width}x#{pane_height}] [history #{history_size}/#{history_limit}, #{history_bytes} bytes] #{?pane_active,[active],[inactive]}\\\""
else
  panes=$(tmux list-panes -a -F "#S:#{window_index}.#{pane_index}: $TMUX_FZF_PANE_FORMAT")
  reload="tmux list-panes -a -F \\\"#S:#{window_index}.#{pane_index}: \$TMUX_FZF_PANE_FORMAT\\\""
fi

OPTS="--header='${BOLD}^J${OFF} join / ${BOLD}^B${OFF} break / ${BOLD}^X${OFF} kill / ${BOLD}^S${OFF} swap' \
--delimiter=': ' \
--bind=\"ctrl-b:execute(echo {+1} | tr ' ' '$NL' | xargs -I _ tmux breakp -s '_' -d)+reload($reload)\" \
--bind=\"ctrl-x:execute(echo {+1} | tr ' ' '$NL' | xargs -I _ tmux killp -t '_')+reload($reload)\" \
--bind=\"ctrl-j:execute(echo {+1} | tr ' ' '$NL' | xargs -I _ tmux joinp -s '_')+reload($reload)\" \
--bind=\"ctrl-s:execute(tmux swapp -s {1})+reload($reload)\" \
--bind='return:execute(tmux switchc -t {1})+abort'"

printf "$panes" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS $TMUX_FZF_PREVIEW_OPTIONS"

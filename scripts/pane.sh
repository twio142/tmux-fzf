#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

current_pane_origin=$(tmux display-message -p '#S:#I.#P: #{window_name}')
current_pane=$(tmux display-message -p '#S:#I.#P')

if [[ -z "$TMUX_FZF_PANE_FORMAT" ]]; then
  panes=$(tmux list-panes -a -F "#S:#I.#P: [#{window_name}:#{pane_title}] #{pane_current_command}  [#{pane_width}x#{pane_height}] [history #{history_size}/#{history_limit}, #{history_bytes} bytes] #{?pane_active,[active],[inactive]}" | sed -E "s/^([^ ]+)/${YELLOW}\1${OFF}/")
  reload="tmux list-panes -a -F \\\"#S:#I.#P: [#{window_name}:#{pane_title}] #{pane_current_command}  [#{pane_width}x#{pane_height}] [history #{history_size}/#{history_limit}, #{history_bytes} bytes] #{?pane_active,[active],[inactive]}\\\" | sed -E \\\"s/^([^ ]+)/${YELLOW}\\\\1${OFF}/\\\""
else
  panes=$(tmux list-panes -a -F "#S:#I.#P: $TMUX_FZF_PANE_FORMAT #{?#{==:#S:#I.#P,$(tmux display -p '#S:#I.#P')}, ,}" | sed -E "s/^([^ ]+)/${YELLOW}\1${OFF}/")
  reload="tmux list-panes -a -F \\\"#S:#I.#P: \$TMUX_FZF_PANE_FORMAT #{?#{==:#S:#I.#P,\\\$(tmux display -p '#S:#I.#P')}, ,}\\\" | sed -E \\\"s/^([^ ]+)/${YELLOW}\\\\1${OFF}/\\\""
fi

OPTS="--header='${BOLD}⌥J${OFF} join / ${BOLD}^B${OFF} break / ${BOLD}^X${OFF} kill / ${BOLD}^S${OFF} swap' \
--delimiter=': ' \
--bind=\"ctrl-b:execute(echo {+1} | tr ' ' '$NL' | xargs tmux breakp -d -s)+reload($reload)\" \
--bind=\"ctrl-x:execute(echo {+1} | tr ' ' '$NL' | xargs tmux killp -t)+reload($reload)\" \
--bind=\"alt-j:execute(echo {+1} | tr ' ' '$NL' | xargs tmux joinp -h -s)+reload($reload)\" \
--bind=\"ctrl-s:execute(tmux swapp -s {1})+reload($reload)\" \
--bind='return:execute(tmux switchc -t {1})+abort'"

printf "$panes" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS $TMUX_FZF_PREVIEW_OPTIONS"

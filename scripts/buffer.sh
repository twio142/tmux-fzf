#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

if ! [ -x "$(command -v copyq)" ]; then
  action="buffer"
elif [ -z "$1" ]; then
  action="system"
else
  action="$1"
fi

if [[ "$action" == "system" ]]; then
  item_numbers=$(copyq count)
  index=0
  contents=""
  while [ "$index" -lt "$item_numbers" ]; do
    _content="$(copyq read ${index} | tr '\n' ' ' | tr '\\n' ' ')"
    contents="${contents}copy${index}: ${_content}\n"
    index=$((index + 1))
  done
  copyq_index=$(printf "$contents" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS --preview=\"echo {} | sed -e 's/^copy//' -e 's/: .*//' | xargs -I{} copyq read {}\"" | sed -e 's/^copy//' -e 's/: .*//')
  [[ -z "$copyq_index" ]] && exit
  echo "$copyq_index" | xargs -I{} sh -c 'tmux set-buffer -b _temp_tmux_fzf "$(copyq read {})" && tmux paste-buffer -b _temp_tmux_fzf && tmux delete-buffer -b _temp_tmux_fzf'
elif [[ "$action" == "buffer" ]]; then
  reload="tmux list-buffers -F \\\"#{buffer_name}: #{buffer_sample}\\\""
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --header='${BOLD}^X${OFF} delete / ${BOLD}^C${OFF} copy / ${BOLD}^V${OFF} paste' \
  --bind=\"ctrl-x:execute(tmux delete-buffer -b {1})+reload($reload)\" \
  --bind='ctrl-c:execute(tmux show-buffer -b {1} | pbcopy)' \
  --bind=\"ctrl-v:execute(pbpaste | tmux load-buffer -)+reload($reload)\""
  selected_buffer=$(tmux list-buffers -F '#{buffer_name}: #{buffer_sample}' | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS --delimiter=':' --preview='tmux show-buffer -b {1}'" | sed 's/: .*$//')
  [[ -z "$selected_buffer" ]] && exit
  echo "$selected_buffer" | xargs -I{} sh -c 'tmux paste-buffer -b {}'
fi

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

edit_buffer() {
  local tmpfile=$(mktemp /tmp/tmux-buf.XXXXXX)
  tmux show-buffer -b "$1" > $tmpfile
  tmux popup -E -w 75% nvim -- $tmpfile
  local output=$(cat $tmpfile)
  rm $tmpfile
  echo "$output" | tmux load-buffer -b "$1" -
}

if [[ "$action" == "system" ]]; then
  item_numbers=$(copyq count)
  index=0
  contents=""
  while [ "$index" -lt "$item_numbers" ]; do
    _content="$(copyq read ${index} | tr '\n' ' ' | tr '\\n' ' ')"
    contents="${contents}copy${index}: ${_content}\n"
    index=$((index + 1))
  done
  copyq_index=$(printf "$contents" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS --preview=\"echo {} | sed -e 's/^copy//' -e 's/: .*//' | xargs -I{} copyq read {}\" --preview-window=wrap" | sed -e 's/^copy//' -e 's/: .*//')
  [[ -z "$copyq_index" ]] && exit
  echo "$copyq_index" | xargs -I{} sh -c 'tmux set-buffer -b _temp_tmux_fzf "$(copyq read {})" && tmux paste-buffer -b _temp_tmux_fzf && tmux delete-buffer -b _temp_tmux_fzf'
elif [[ "$action" == "buffer" ]]; then
  reload="tmux list-buffers -F \\\"#{buffer_name}  #{buffer_sample}\\\" | sed -E \\\"s/^([^ ]+)/${YELLOW}\\\\1${OFF}/\\\""
  FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --header='${BOLD}^X${OFF} delete / ${BOLD}^C${OFF} copy / ${BOLD}^V${OFF} paste / ${BOLD}^E${OFF} edit' \
  --bind=\"ctrl-x:execute(tmux delete-buffer -b {1})+reload($reload)\" \
  --bind='ctrl-c:execute(tmux show-buffer -b {1} | pbcopy)' \
  --bind=\"ctrl-v:execute(pbpaste | tmux load-buffer -)+reload($reload)\" \
  --bind='ctrl-e:print(--edit)+accept'"
  output=$(tmux list-buffers -F '#{buffer_name}  #{buffer_sample}' | sed -E "s/^([^ ]+)/${YELLOW}\1${OFF}/" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS --ansi --delimiter='  ' --preview='tmux show-buffer -b {1}' --preview-window=wrap " --accept-nth=1)
  [[ -z "$output" ]] && exit
  if [ $(echo "$output" | head -n1) == '--edit' ]; then
    buf=$(echo "$output" | sed '2!d')
    edit_buffer "$buf"
  else
    echo "$output" | xargs -I{} sh -c 'tmux paste-buffer -b {}'
  fi
fi

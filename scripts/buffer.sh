#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

action="${1:-buffer}"

edit_buffer() {
  local tmpfile=$(mktemp /tmp/tmux-buf.XXXXXX)
  tmux show-buffer -b "$1" > $tmpfile
  tmux popup -E -w 75% nvim -- $tmpfile
  local output=$(cat $tmpfile)
  rm $tmpfile
  printf "$output" | tmux load-buffer -b "$1" -
}

edit_clipboard() {
  local tmpfile=$(mktemp /tmp/tmux-buf.XXXXXX)
  echo "$1" > $tmpfile
  tmux popup -E -w 75% nvim -- $tmpfile
  local output=$(cat $tmpfile)
  rm $tmpfile
  printf "$output" | pbcopy
}

if [[ "$action" == "system" ]]; then
  [ -x "$(command -v copyq)" ] || exit 1
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
elif [[ "$action" == "alfred" ]]; then
  DB_PATH="$HOME/Library/Application Support/Alfred/Databases/clipboard.alfdb"
  [[ -x "$(command -v sqlite3)" && -f "$DB_PATH" ]] || exit 1
  TMUX_FZF_OPTIONS="$TMUX_FZF_OPTIONS \
  --preview-label=' Clipboard History ' --preview-label-pos bottom \
  --preview \"chafa -f symbols '$DB_PATH.data'/{1} 2>/dev/null || echo {2..}\" --preview-window=wrap \
  --header='${BOLD}^Y${OFF} yank / ${BOLD}^E${OFF} edit' \
  --bind='enter:execute(printf {2..} | tmux load-buffer -b _ - \\; pasteb -d -b _)+cancel' \
  --bind='ctrl-y:execute(printf {2..} | tmux load-buffer -)' \
  --bind='ctrl-e:become(printf {2..})+cancel'"
  QUERY="SELECT item,dataHash FROM clipboard ORDER BY ts DESC LIMIT 20" 
  output=$(sqlite3 -json "$DB_PATH" "$QUERY" | jq -r 'map(.dataHash + "\n" + .item) | join("\u0000")' | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS +m --read0 --delimiter '\n' --with-nth=2..")
  [[ -z "$output" ]] || edit_clipboard "$output"
elif [[ "$action" == "buffer" ]]; then
  reload="tmux list-buffers -F \\\"${YELLOW}#{buffer_name}${OFF}  #{buffer_sample}\\\""
  TMUX_FZF_OPTIONS="$TMUX_FZF_OPTIONS \
  --preview-label=' Tmux Buffers ' --preview-label-pos bottom \
  --header='${BOLD}^X${OFF} delete / ${BOLD}^C${OFF} copy / ${BOLD}^E${OFF} edit' \
  --bind='enter:execute(echo {+1} | xargs -I_ -n 1 tmux pasteb -b _ \\; send Space)+cancel' \
  --bind=\"ctrl-x:execute(echo {+1} | xargs -n 1 tmux deleteb -b)+reload($reload)\" \
  --bind='ctrl-c:execute(tmux show-buffer -b {1} | pbcopy)' \
  --bind='ctrl-e:become(echo {1})+cancel'"
  output=$(tmux list-buffers -F "${YELLOW}#{buffer_name}${OFF}  #{buffer_sample}" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS --delimiter='  ' --preview='tmux show-buffer -b {1}' --preview-window=wrap ")
  [[ -z "$output" ]] || edit_buffer "$output"
fi

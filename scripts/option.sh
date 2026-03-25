#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/.envs"

mode="${1:-option}"

case "$mode" in
  option)
    local_reload="tmux show-options"
    global_reload="tmux show-options -g"
    local_label="Options"
    global_label="Global Options"
    set_cmd="set-option"
    ;;
  env)
    local_reload="bash $CURRENT_DIR/_env_list.sh"
    global_reload="bash $CURRENT_DIR/_env_list.sh -g"
    local_label="Environment Variables"
    global_label="Global Environment Variables"
    set_cmd="set-environment"
    ;;
  *)
    exit 1
    ;;
esac

data=$(eval "$local_reload")

OPTS="--header='${BOLD}↩${OFF} edit / ${BOLD}^G${OFF} toggle global / ${BOLD}^Y${OFF} yank / ${BOLD}^X${OFF} unset' --with-nth=1 \
--preview-label=' $local_label ' --preview-label-pos bottom \
--preview='echo {2..}' --preview-window=wrap \
--bind='ctrl-g:transform([[ \"\$FZF_PREVIEW_LABEL\" == *Global* ]] && echo \"reload($local_reload)\" || echo \"reload($global_reload)\")+transform-preview-label:[[ \"\$FZF_PREVIEW_LABEL\" == *Global* ]] && echo \" $local_label \" || echo \" $global_label \"' \
--bind='ctrl-y:execute-silent(printf {2..} | tmux load-buffer -)' \
--bind='return:transform(if [[ \"\$FZF_PREVIEW_LABEL\" == *Global* ]]; then echo \"become(echo global; echo {1}; echo {2..})\"; else echo \"become(echo local; echo {1}; echo {2..})\"; fi)' \
--bind='ctrl-x:execute-silent([[ \"\$FZF_PREVIEW_LABEL\" == *Global* ]] && tmux $set_cmd -g -u {1} || tmux $set_cmd -u {1})+transform([[ \"\$FZF_PREVIEW_LABEL\" == *Global* ]] && echo \"reload($global_reload)\" || echo \"reload($local_reload)\")'"

output=$(printf '%s\n' "$data" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS $OPTS")

[ -z "$output" ] && exit 0
{ read -r scope; read -r name; value=$(cat); } <<< "$output"

if [[ "$scope" == global ]]; then
  tmux command-prompt -p "$set_cmd $name:" -I "$value" "$set_cmd -g $name '%%'"
else
  tmux command-prompt -p "$set_cmd $name:" -I "$value" "$set_cmd $name '%%'"
fi

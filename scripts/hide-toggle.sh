#!/usr/bin/env bash
# Hide a floating, non-modal pane by shrinking it to one borderless cell, or restore it.
# @hide_geom holds "W H X Y BORDER" (outer geometry, "-" for an inherited border); being set means hidden.
# Hiding the active pane moves focus to another visible pane in its window; showing a pane focuses it.

for p in "$@"; do
  # modal panes keep focus, so a hidden one would swallow keys unseen
  [[ $(tmux display -p -t "$p" '#{&&:#{pane_floating_flag},#{!:#{pane_modal_flag}}}' 2>/dev/null) == 1 ]] || continue
  if read -r w h x y bl <<< "$(tmux show -pv -t "$p" @hide_geom 2>/dev/null)" && [[ -n $w ]]; then
    if [[ $bl == - ]]; then tmux set -pu -t "$p" pane-border-lines; else tmux set -p -t "$p" pane-border-lines "$bl"; fi
    tmux resizep -t "$p" -x "$w" -y "$h" \; movep -t "$p" -X "$x" -Y "$y" \; set -pu -t "$p" @hide_geom \; selectp -t "$p"
  else
    other=
    [[ $(tmux display -p -t "$p" '#{pane_active}') == 1 ]] &&
      other=$(tmux lsp -t "$p" -f "#{&&:#{!=:#{pane_id},$p},#{!:#{@hide_geom}}}" -F '#{pane_id}' | head -1)
    bl=$(tmux show -pv -t "$p" pane-border-lines) b=1
    [[ $bl == none ]] && b=0
    geom=$(tmux display -p -t "$p" "#{e|+:#{pane_width},$((2 * b))} #{e|+:#{pane_height},$((2 * b))} #{e|-:#{pane_left},$b} #{e|-:#{pane_top},$b}")
    tmux set -p -t "$p" @hide_geom "$geom ${bl:--}" \; set -p -t "$p" pane-border-lines none \; \
      resizep -t "$p" -x 1 -y 1 \; movep -t "$p" -P bottom-right
    [[ -n $other ]] && tmux selectp -t "$other"
  fi
done

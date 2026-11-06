#!/usr/bin/env bash
# Float a tiled pane, or return a floating pane to its place in the layout.
# A float's outer geometry is kept in @float_geom so it survives parking in another window.
geom='#{e|+:#{pane_width},2} #{e|+:#{pane_height},2} #{e|-:#{pane_left},1} #{e|-:#{pane_top},1}'
for p in "$@"; do
  # tmux refuses to unfloat a modal pane
  [[ $(tmux display -p -t "$p" '#{pane_modal_flag}') == 1 ]] && continue
  if [[ $(tmux display -p -t "$p" '#{pane_floating_flag}') == 1 ]]; then
    # unhide first so the saved geometry is the real one
    [[ -n $(tmux show -pv -t "$p" @hide_geom 2>/dev/null) ]] && "$(dirname "$0")/hide-toggle.sh" "$p"
    tmux set -pF -t "$p" @float_geom "$geom"
    tmux joinp -s "$p" -t "$p"
  elif read -r w h x y <<< "$(tmux show -pv -t "$p" @float_geom 2>/dev/null)" && [[ -n $w ]]; then
    tmux breakp -W -d -s "$p" -x "$w" -y "$h" -X "$x" -Y "$y"
    tmux set -pu -t "$p" @float_geom
  else
    # evaluated against the pane's own window: breakp would use the current one
    read -r w h x y <<< "$(tmux display -p -t "$p" '#{E:@float_w} #{E:@float_h} #{E:@float_x} #{E:@float_y}')"
    tmux breakp -W -d -s "$p" -x "$w" -y "$h" -X "$x" -Y "$y"
  fi
done

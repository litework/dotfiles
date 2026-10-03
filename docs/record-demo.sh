#!/bin/sh
# docs/record-demo.sh — record docs/demo.gif: a quick scripted tour of the desktop.
# Drives sway and the flyouts over IPC/D-Bus (no synthetic input), on an empty workspace,
# with the panel in demo mode (QP_DEMO=1) so the Wi-Fi name and city stay out of it.
# Needs: wf-recorder, ffmpeg, cmatrix. Don't touch the mouse/keyboard while it runs (~30 s).
set -eu
cd "$(dirname "$0")"
tmp=$(mktemp -d)
qp=~/.local/bin/quick-panel
nav() { gdbus call --session --dest dev.litework.QuickPanel --object-path /dev/litework/QuickPanel \
        --method org.gtk.Actions.Activate navigate "[<'$1'>]" "{}" >/dev/null; }
restart_panel() {
    pkill -f '^/usr/bin/python3 .*quick-panel-service' || true
    while pgrep -f '^/usr/bin/python3 .*quick-panel-service' >/dev/null; do sleep 0.2; done
    env "$@" setsid -f ~/.local/bin/quick-panel-service --daemon >/dev/null 2>&1
    sleep 3
}
# fastfetch prints once the other windows have tiled, so it lays out at its final width.
fetch="sh -c 'sleep 2.9; exec fastfetch -c $PWD/fastfetch-demo.jsonc'"

previous=$(swaymsg -t get_workspaces | python -c 'import json,sys; print(next(w["name"] for w in json.load(sys.stdin) if w["focused"]))')
restart_panel QP_DEMO=1
~/.local/bin/weather update >/dev/null   # fresh forecast so the flyout fills instantly
swaymsg -q workspace number 9
sleep 0.5

wf-recorder -r 20 -f "$tmp/demo.mp4" >/dev/null 2>&1 &
rec=$!
sleep 1

# Windows tile in: fastfetch | neovim over cmatrix
swaymsg -q exec "foot --app-id=demo-fetch --hold $fetch";                          sleep 1.2
swaymsg -q exec "foot --app-id=demo-nvim nvim -R $HOME/dotfiles/sway/.config/sway/fx.conf"; sleep 1.3
swaymsg -q '[app_id="demo-nvim"] focus' && swaymsg -q splitv
swaymsg -q exec "foot --app-id=demo-matrix cmatrix -b -u 8";                       sleep 1.6

# Flyouts
$qp start;                 sleep 1.3
$qp search ed;             sleep 1.1
$qp search '12*7+1';       sleep 1.1
$qp start;                 sleep 0.4
$qp control;               sleep 1.6
nav appearance;            sleep 1.2
$qp control;               sleep 0.4
$qp osd volume;            sleep 1.8
$qp calendar;              sleep 1.5
$qp calendar;              sleep 0.3
$qp weather;               sleep 1.5
$qp weather;               sleep 0.4

# Windows close
swaymsg -q '[app_id="demo-matrix"] kill';   sleep 0.5
swaymsg -q '[app_id="demo-nvim"] kill';     sleep 0.5
swaymsg -q '[app_id="demo-fetch"] kill';    sleep 0.8

kill -INT $rec; wait $rec || true
swaymsg -q workspace "$previous"
restart_panel

ffmpeg -loglevel error -y -i "$tmp/demo.mp4" -vf \
  "fps=12,scale=880:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
  demo.gif
rm -rf "$tmp"
ls -la demo.gif

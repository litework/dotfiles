#!/bin/sh
# docs/record-demo.sh — record docs/demo.gif: a scripted tour of the desktop.
# Drives the flyouts over D-Bus (no synthetic input), on an empty workspace, with the
# panel in demo mode (QP_DEMO=1) so the Wi-Fi name and city stay out of the recording.
# Needs: wf-recorder, ffmpeg. Don't touch the mouse/keyboard while it runs (~35 s).
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

previous=$(swaymsg -t get_workspaces | python -c 'import json,sys; print(next(w["name"] for w in json.load(sys.stdin) if w["focused"]))')
restart_panel QP_DEMO=1
swaymsg -q workspace number 9
swaymsg -q exec 'foot --app-id=demo --hold fastfetch --structure Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:Display:WM:Theme:Icons:Cursor:Terminal:CPU:GPU:Memory:Disk:Battery:Break:Colors'
sleep 2.5

wf-recorder -r 15 -f "$tmp/demo.mp4" >/dev/null 2>&1 &
rec=$!
sleep 2

$qp start;                 sleep 2.5
$qp search ed;             sleep 2.5
$qp search '12*7+1';       sleep 2.5
$qp start;                 sleep 0.8
$qp control;               sleep 3
nav appearance;            sleep 2.5
$qp control;               sleep 0.8
$qp osd volume;            sleep 2
$qp calendar;              sleep 3.5
$qp calendar;              sleep 0.8
$qp weather;               sleep 3.5
$qp weather;               sleep 1.5

kill -INT $rec; wait $rec || true
swaymsg -q '[app_id="demo"] kill'
swaymsg -q workspace "$previous"
restart_panel

ffmpeg -loglevel error -y -i "$tmp/demo.mp4" -vf \
  "fps=12,scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=128:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
  demo.gif
rm -rf "$tmp"
ls -la demo.gif

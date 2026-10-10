#!/usr/bin/env bash
# Run the greeter in test mode and screenshot each of its windows (grim).
#
# The theme is copied to a temp dir first, so a test theme.conf.user (to try
# a synced palette or light mode) never lands in the repo.
#
#   ./test.sh                         # open theme/ and take screenshots
#   ./test.sh -c light.conf           # same, with light.conf as theme.conf.user
#   ./test.sh -r                      # real mode: no testMode=true (see theme.conf)
#   ./test.sh -k                      # keep the greeter open after the shots
#   ./test.sh -n                      # no screenshots, just open it
#   ./test.sh -d 4 -t /path/to/theme  # wait 4s before the shots, other theme
#   ./test.sh -s keys:a,b,Return -s wait:1 -s shot:failed
#                                     # steps instead of the single shot: keys
#                                     # (Hyprland names, MOD+key), wait, shot
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
theme="$repo/theme"
user_conf=""
delay=2
shots=1
keep=0
test_mode=1
steps=()
out="$repo/screenshots"

usage() {
    sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while getopts "t:c:d:o:s:knrh" opt; do
    case $opt in
    t) theme=$(realpath "$OPTARG") ;;
    c) user_conf=$(realpath "$OPTARG") ;;
    d) delay=$OPTARG ;;
    o) out=$OPTARG ;;
    k) keep=1 ;;
    n) shots=0 keep=1 ;;
    r) test_mode=0 ;;
    s) steps+=("$OPTARG") ;;
    h) usage ;;
    *) usage 1 ;;
    esac
done

for cmd in sddm-greeter-qt6 hyprctl jq; do
    command -v "$cmd" >/dev/null || { echo "missing: $cmd" >&2; exit 1; }
done
((shots)) && ! command -v grim >/dev/null && { echo "missing: grim" >&2; exit 1; }
[[ -f $theme/metadata.desktop ]] || { echo "not a theme dir: $theme" >&2; exit 1; }

tmp=$(mktemp -d)
cp -r "$theme" "$tmp/theme"
conf="$tmp/theme/theme.conf.user"
if [[ -n $user_conf ]]; then
    cp "$user_conf" "$conf"
else
    echo "[General]" >"$conf"
fi
((test_mode)) && echo "testMode=true" >>"$conf"

start=$(date +%s)
sddm-greeter-qt6 --test-mode --theme "$tmp/theme" >/dev/null 2>&1 &
pid=$!
cleanup() {
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    rm -rf "$tmp"
}
trap cleanup EXIT

sleep "$delay"
if ! kill -0 "$pid" 2>/dev/null; then
    echo "greeter exited early:" >&2
    journalctl --since "@$start" --no-pager -o cat _PID="$pid" >&2
    exit 1
fi

# "monitor address x,y wxh" per greeter window (one per monitor)
windows() {
    hyprctl clients -j | jq -r --argjson pid "$pid" \
        '.[] | select(.pid == $pid) | "\(.monitor) \(.address) \(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

shot() {
    mkdir -p "$out"
    windows | while read -r mon _ pos size; do
        file="$out/$stamp-${1:+$1-}mon$mon.png"
        grim -g "$pos $size" "$file"
        echo "$file"
    done
}

# Keys only reach the focused window; the secondary screens ignore them
send_keys() {
    windows | while read -r _ addr _; do
        hyprctl dispatch "hl.dsp.focus({ window = 'address:$addr' })" >/dev/null
        IFS=, read -ra keys <<<"$1"
        for key in "${keys[@]}"; do
            mods=""
            [[ $key == *+* ]] && mods=${key%+*} key=${key##*+}
            hyprctl dispatch "hl.dsp.send_shortcut({ mods = '$mods', key = '$key', window = 'address:$addr' })" >/dev/null
        done
    done
}

stamp=$(date +%Y%m%d-%H%M%S)
if ((${#steps[@]})); then
    for step in "${steps[@]}"; do
        case $step in
        keys:*) send_keys "${step#keys:}" ;;
        wait:*) sleep "${step#wait:}" ;;
        shot:*) shot "${step#shot:}" ;;
        *) echo "unknown step: $step" >&2 ;;
        esac
    done
elif ((shots)); then
    shot ""
fi

# The greeter logs to the journal: QML warnings, errors and console output
journalctl --since "@$start" --no-pager -o cat _PID="$pid" |
    grep -vE "^(Loading |Reading from|Connecting to|Socket server|Adding view|Message received|High-DPI|Socket error)|QWaylandTextInputv3|Cannot open: .*/avatars/" || true

if ((keep)); then
    echo "greeter running (pid $pid), Ctrl+C to close"
    wait "$pid" || true
fi

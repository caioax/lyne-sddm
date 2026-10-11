#!/usr/bin/env bash
# Run the greeter in test mode and screenshot each of its windows (grim).
#
# The theme is copied to a temp dir first, so a test theme.conf.user (to try
# a synced palette or light mode) never lands in the repo.
#
#   ./test.sh                         # open theme/ and take screenshots
#   ./test.sh -c light.conf           # same, with light.conf as theme.conf.user
#   ./test.sh -a face.png             # as the synced avatar of $USER
#   ./test.sh -D /tmp/data            # synced dir to use instead of dataDir
#                                     # (its theme.conf.user and avatars)
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
avatar=""
data_dir=""
delay=2
shots=1
keep=0
test_mode=1
steps=()
out="$repo/screenshots"

usage() {
    sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while getopts "t:c:a:D:d:o:s:knrh" opt; do
    case $opt in
    t) theme=$(realpath "$OPTARG") ;;
    c) user_conf=$(realpath "$OPTARG") ;;
    a) avatar=$(realpath "$OPTARG") ;;
    D) data_dir=$(realpath "$OPTARG") ;;
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
# The overrides: -c, else the -D dir's, else the theme's own (an installed
# theme links it into dataDir, maybe not created yet). Always a plain copy,
# so the test keys below never reach the real synced file
conf_src=$user_conf
[[ -z $conf_src && -n $data_dir ]] && conf_src=$data_dir/theme.conf.user
[[ -z $conf_src ]] && conf_src=$conf
if [[ -f $conf_src ]]; then
    content=$(cat "$conf_src")
else
    content="[General]"
fi
rm -f "$conf"
printf '%s\n' "$content" | sed -E '/^(testMode|dataDir)=/d' >"$conf"
((test_mode)) && echo "testMode=true" >>"$conf"
# -a wins over -D for the avatar; without either, the theme's dataDir
if [[ -n $avatar ]]; then
    mkdir -p "$tmp/data/avatars"
    cp "$avatar" "$tmp/data/avatars/$USER.png"
    echo "dataDir=$tmp/data" >>"$conf"
elif [[ -n $data_dir ]]; then
    echo "dataDir=$data_dir" >>"$conf"
fi

start=$(date +%s)
# On Wayland the OpenGL backend gets an RGB565 surface (banding in the blur);
# the real greeter runs on X11 with 8 bits per channel, and Vulkan matches it
QSG_RHI_BACKEND=${QSG_RHI_BACKEND:-vulkan} sddm-greeter-qt6 --test-mode --theme "$tmp/theme" >/dev/null 2>&1 &
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
        # Vulkan breaks when the GPU driver was updated without a reboot
        if command -v magick >/dev/null && [[ $(magick "$file" -format '%[fx:mean==0]' info:) == 1 ]]; then
            echo "warning: $file is all black; try QSG_RHI_BACKEND=opengl ./test.sh" >&2
        fi
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

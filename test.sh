#!/usr/bin/env bash
# Run the greeter in test mode and screenshot each of its windows (grim).
#
# The theme is copied to a temp dir first, so a test theme.conf.user (to try
# a synced palette or light mode) never lands in the repo.
#
#   ./test.sh                         # open theme/ and take screenshots
#   ./test.sh -c light.conf           # same, with light.conf as theme.conf.user
#   ./test.sh -k                      # keep the greeter open after the shots
#   ./test.sh -n                      # no screenshots, just open it
#   ./test.sh -d 4 -t /path/to/theme  # wait 4s before the shots, other theme
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
theme="$repo/theme"
user_conf=""
delay=2
shots=1
keep=0
out="$repo/screenshots"

usage() {
    sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while getopts "t:c:d:o:knh" opt; do
    case $opt in
    t) theme=$(realpath "$OPTARG") ;;
    c) user_conf=$(realpath "$OPTARG") ;;
    d) delay=$OPTARG ;;
    o) out=$OPTARG ;;
    k) keep=1 ;;
    n) shots=0 keep=1 ;;
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
[[ -n $user_conf ]] && cp "$user_conf" "$tmp/theme/theme.conf.user"

sddm-greeter-qt6 --test-mode --theme "$tmp/theme" >"$tmp/greeter.log" 2>&1 &
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
    cat "$tmp/greeter.log" >&2
    exit 1
fi

if ((shots)); then
    mkdir -p "$out"
    stamp=$(date +%Y%m%d-%H%M%S)
    # One fullscreen window per monitor
    hyprctl clients -j | jq -r --argjson pid "$pid" \
        '.[] | select(.pid == $pid) | "\(.monitor) \(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
        while read -r mon pos size; do
            file="$out/$stamp-mon$mon.png"
            grim -g "$pos $size" "$file"
            echo "$file"
        done
fi

# QML warnings and errors
grep -iE "warning|error|qrc:|file:" "$tmp/greeter.log" | grep -v "^$" || true

if ((keep)); then
    echo "greeter running (pid $pid), Ctrl+C to close"
    wait "$pid" || true
fi

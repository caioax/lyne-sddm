#!/usr/bin/env bash
# Regenerate theme/layouts/<Name>.png, the thumbnail of each layout (shown by
# lyne-dots in its layout picker): a test.sh screenshot of the primary
# screen, idle, with the theme defaults, scaled to 480x270. Dev only; run it
# after changing a layout and commit the result.
#
#   tools/gen-thumbnails.sh            # every layout
#   tools/gen-thumbnails.sh cards      # only these ids
#
# No synced data is used (an empty dataDir): the avatar is the silhouette,
# never a real picture, and the palette and wallpaper are the defaults.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
layouts=$repo/theme/layouts
size=480x270

command -v magick >/dev/null || { echo "missing: magick" >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/data"

ids=("$@")
if ((${#ids[@]} == 0)); then
    for qml in "$layouts"/*.qml; do
        name=$(basename "$qml" .qml)
        ids+=("${name,,}")
    done
fi

for id in "${ids[@]}"; do
    name=${id^}
    [[ -f $layouts/$name.qml ]] || { echo "no layout $id ($name.qml)" >&2; exit 1; }
    printf '[General]\nlayout=%s\n' "$id" >"$tmp/$id.conf"
    mkdir "$tmp/$id"
    # Long enough for the reveal animations to settle
    "$repo/test.sh" -c "$tmp/$id.conf" -D "$tmp/data" -o "$tmp/$id" -d 3 >"$tmp/$id.log" 2>&1 ||
        { cat "$tmp/$id.log" >&2; exit 1; }
    # Monitor 0 holds the primary screen here; check the result by eye
    shot=$(grep -m1 -- '-mon0\.png$' "$tmp/$id.log") || { cat "$tmp/$id.log" >&2; exit 1; }
    magick "$shot" -resize "$size^" -gravity center -extent "$size" -strip \
        -define png:compression-level=9 -define png:compression-filter=5 \
        "$layouts/$name.png"
    echo "$name.png: $(du -h "$layouts/$name.png" | cut -f1)"
done

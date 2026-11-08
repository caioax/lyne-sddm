#!/usr/bin/env bash
# Install lyne-sddm system-wide, update it, or remove it. Never restarts SDDM.
#
#   ./install.sh --dry-run               # show every step, change nothing
#   ./install.sh                         # install or update, and select it
#   ./install.sh --uninstall --dry-run
#   ./install.sh --uninstall             # remove it, its synced files and lyne.conf
#   ./install.sh --user NAME             # owner of the synced files (default: you)
#
# The look, without lyne-dots (no sudo; written to /var/lib/lyne-sddm, so run
# the install first). Options combine and keep earlier choices:
#
#   ./install.sh --list-presets          # palettes for --preset
#   ./install.sh --list-layouts          # layouts for --layout
#   ./install.sh --preset nord --layout cards
#   ./install.sh --wallpaper ~/pic.jpg   # copied in; "default" = the theme's
#   ./install.sh --opacity 0.8           # cards and pills, 0..1
#   ./install.sh --reset                 # back to the theme's defaults
#
# While the lyne-dots sync is on, lyne-dots owns the look: these refuse to
# change it (turn the sync off in its Settings › Theme › Login screen).
#
# theme/ goes to /usr/share/sddm/themes/lyne (root-owned). /var/lib/lyne-sddm
# belongs to you: lyne-dots writes theme.conf.user, the wallpaper and the
# avatars there without sudo (theme.conf.user in the theme dir is a symlink
# to it). /etc/sddm.conf.d/lyne.conf selects the theme; removing it brings
# back whatever the other SDDM config files select. Asks for the sudo password.
#
# The lyne-sddm-git package installs this script as `lyne-sddm`. Without a
# theme/ dir next to it, it leaves the theme files to pacman and only sets up
# /var/lib/lyne-sddm and lyne.conf (--uninstall removes just those).
#
# Testing: LYNE_SDDM_PREFIX=/some/dir puts every system path under that dir
# and runs the steps as you, without sudo.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
src="$repo/theme"
cmd=$(basename "$0")
name=lyne
prefix=${LYNE_SDDM_PREFIX:-}
themes=$prefix/usr/share/sddm/themes
dest=$themes/$name
confdir=$prefix/etc/sddm.conf.d
conf=$confdir/lyne.conf
# Synced files (theme.conf's dataDir); before 0.1.0 they lived in $dest/user
data=$prefix/var/lib/lyne-sddm
old_data=$dest/user
dry=0
uninstall=0
# Look options (--preset, --layout, --wallpaper, --opacity, --reset, --list)
declare -A look=()
owner=${SUDO_USER:-$USER}
# Run from the package: the theme files belong to pacman
packaged=0
[[ -f $src/metadata.desktop ]] || packaged=1

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
explained=0
die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    explained=1
    exit 1
}

# The comment block at the top of this file
usage() {
    awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
    exit "${1:-0}"
}

while (($#)); do
    case $1 in
    -n | --dry-run) dry=1 ;;
    -u | --uninstall) uninstall=1 ;;
    --preset | --layout | --wallpaper | --opacity)
        [[ $# -ge 2 && -n $2 ]] || die "$1 needs a value"
        look[${1#--}]=$2
        shift
        ;;
    --reset) look[reset]=1 ;;
    --list-presets) look[list]=presets ;;
    --list-layouts) look[list]=layouts ;;
    --user)
        owner=${2:?--user needs a name}
        shift
        ;;
    -h | --help) usage ;;
    *) usage 1 ;;
    esac
    shift
done

# A failed step (a cancelled or refused sudo prompt included) stops the
# script through set -e: say so instead of leaving only that command's output
failed() {
    local rc=$1
    ((rc == 0 || explained)) && return
    printf '\033[1;31merror:\033[0m %s\n' \
        "stopped (exit $rc) before the end: the steps after the last \":: \" line were not done; run $cmd again" >&2
}
trap 'failed $?' EXIT

# Runs a command as root; under --dry-run it only prints it
root() {
    if ((dry)); then
        printf '   [dry-run] %s\n' "$*"
    elif ((EUID == 0)) || [[ -n $prefix ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# Runs a command as the owner of the synced files, so root never writes
# inside a dir a user controls (a planted symlink would redirect it)
as_owner() {
    if ((dry)); then
        printf '   [dry-run] (as %s) %s\n' "$owner" "$*"
    elif [[ -n $prefix ]] || [[ $owner == "$(id -un)" ]]; then
        "$@"
    else
        sudo -u "$owner" -- "$@"
    fi
}

# Writes stdin to a file: write_file root|owner PATH MODE
write_file() {
    local who=$1 path=$2 mode=$3 content
    content=$(cat)
    if ((dry)); then
        printf '   [dry-run] write %s (%s, %s):\n' "$path" "$mode" "$([[ $who == root ]] && echo root || echo "$owner")"
        printf '%s\n' "$content" | sed 's/^/   [dry-run]   | /'
        return
    fi
    if [[ $who == root ]]; then
        printf '%s\n' "$content" | root install -m "$mode" /dev/stdin "$path"
    else
        printf '%s\n' "$content" | as_owner install -m "$mode" /dev/stdin "$path"
    fi
}

# The theme SDDM ends up with, as "<theme>|<file that sets it>": config files
# are read in name order (/usr/lib, then /etc), /etc/sddm.conf last, and the
# last Current= wins. $1 = 1 counts lyne.conf as present (it may not exist
# yet under --dry-run), 0 leaves it out
effective_theme() {
    local with=$1 theme="" from="" file value
    local -a files
    mapfile -t files < <(
        {
            compgen -G "$confdir/*.conf" || true
            ((with)) && echo "$conf"
        } | LC_ALL=C sort -u
    )
    for file in "$prefix"/usr/lib/sddm/sddm.conf.d/*.conf "${files[@]}" "$prefix/etc/sddm.conf"; do
        if [[ $file == "$conf" ]]; then
            ((with)) || continue
            theme=$name from=$file
            continue
        fi
        [[ -f $file ]] || continue
        # Last "Current=" inside [Theme]; "set" tells an empty value apart
        value=$(awk -F= '
            /^[[:space:]]*\[/ { section = $0; gsub(/[[:space:]]/, "", section) }
            section == "[Theme]" && $1 ~ /^[[:space:]]*Current[[:space:]]*$/ {
                sub(/^[^=]*=[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); last = "set:" $0
            }
            END { print last }' "$file")
        [[ $value == set:* ]] && theme=${value#set:} from=$file
    done
    printf '%s|%s\n' "$theme" "$from"
}

describe() {
    local theme=${1%%|*} from=${1#*|}
    if [[ -z $theme ]]; then
        echo "SDDM's built-in default${from:+ (empty Current= in $from)}"
    else
        echo "\"$theme\" (from $from)"
    fi
}

# The file the install creates and lyne-dots puts back when its sync goes
# off: lyne-dots keeps a copy of this text (SDDM_DEFAULT_CONF), keep both equal
default_conf() {
    cat <<'EOF'
[General]
# Overrides of theme.conf, written by lyne-dots (see docs/sync.md).
# Empty: the theme's defaults (Tokyo Night).
EOF
}

# ============================================================================
# LOOK: --preset, --layout, --wallpaper, --opacity, --reset, --list-* (no sudo)
# ============================================================================
if ((${#look[@]})); then
    ((uninstall)) && die "--uninstall doesn't mix with the look options"
    # The installed theme (what the greeter shows), else this repo's
    theme_dir=$dest
    [[ -f $theme_dir/metadata.desktop ]] || theme_dir=$src
    [[ -f $theme_dir/metadata.desktop ]] || die "theme not found in $dest: install it first"

    if [[ -n ${look[list]:-} ]]; then
        ((${#look[@]} == 1)) || die "--list-${look[list]} goes alone"
        shopt -s nullglob
        if [[ ${look[list]} == presets ]]; then
            for f in "$theme_dir"/presets/*.conf; do basename "$f" .conf; done
        else
            for f in "$theme_dir"/layouts/*.qml; do
                f=$(basename "$f" .qml)
                echo "${f,,}"
            done
        fi
        exit 0
    fi
    if [[ -n ${look[reset]:-} ]] && ((${#look[@]} > 1)); then
        die "--reset goes alone"
    fi

    # Root writing in a dir a user controls could be redirected by a link
    ((EUID == 0)) && [[ -z $prefix ]] && die "run this as your user, without sudo"
    file=$data/theme.conf.user
    [[ -d $data ]] || die "$data doesn't exist: run $cmd (the install) first"
    [[ -O $data ]] || die "$data belongs to $(stat -c %U "$data"): run this as that user"
    if grep -q '^# Written by lyne-dots' "$file" 2>/dev/null; then
        die "lyne-dots syncs the login screen: change it in its Settings › Theme › Login screen, or turn the sync off there first"
    fi
    manual=0
    grep -q '^# Written by lyne-sddm' "$file" 2>/dev/null && manual=1
    # Neither ours nor the empty template: someone edited it by hand
    if ((!manual)) && [[ -f $file && $(<"$file") != "$(default_conf)" && -z ${look[reset]:-} ]]; then
        die "$file has changes of its own: move it away, or start over with --reset"
    fi

    # Moves the content of stdin into place in one step
    put() {
        local target=$1 tmp
        if ((dry)); then
            printf '   [dry-run] write %s:\n' "$target"
            sed 's/^/   [dry-run]   | /'
            return
        fi
        tmp=$(mktemp "$data/.lyne-sddm.XXXXXX")
        cat >"$tmp"
        chmod 644 "$tmp"
        mv -f "$tmp" "$target"
    }
    # Removes the wallpaper copies, all but $1
    drop_wallpapers() {
        local f
        for f in "$data"/wallpaper.*; do
            [[ -e $f && $f != "${1:-}" ]] || continue
            if ((dry)); then printf '   [dry-run] rm %s\n' "$f"; else rm -f "$f"; fi
        done
    }

    if [[ -n ${look[reset]:-} ]]; then
        default_conf | put "$file"
        drop_wallpapers
        say "Back to the theme's defaults"
        exit 0
    fi

    # Earlier manual choices stay unless replaced
    declare -A keys=()
    if ((manual)); then
        while IFS= read -r line; do
            [[ $line =~ ^([A-Za-z0-9]+)=(.*)$ ]] && keys[${BASH_REMATCH[1]}]=${BASH_REMATCH[2]}
        done <"$file"
    fi
    palette=(background surface0 surface1 surface2 surface3 text textReverse subtext
        accent success warning error muted)

    if [[ -n ${look[preset]:-} ]]; then
        id=${look[preset],,}
        preset=$theme_dir/presets/$id.conf
        [[ $id =~ ^[a-z0-9-]+$ && -f $preset ]] ||
            die "no preset \"${look[preset]}\" (see --list-presets)"
        for key in "${palette[@]}"; do
            value=$(sed -n "s/^$key=//p" "$preset" | tail -1)
            [[ -n $value ]] || die "$preset has no $key"
            keys[$key]=$value
        done
        keys[preset]=$id
        say "Palette: $id"
    fi

    if [[ -n ${look[layout]:-} ]]; then
        id=${look[layout],,}
        [[ $id =~ ^[a-z]+$ && -f $theme_dir/layouts/${id^}.qml ]] ||
            die "no layout \"${look[layout]}\" (see --list-layouts)"
        keys[layout]=$id
        say "Layout: $id"
    fi

    if [[ -n ${look[opacity]:-} ]]; then
        value=${look[opacity]}
        [[ $value =~ ^(0(\.[0-9]+)?|1(\.0+)?|\.[0-9]+)$ ]] ||
            die "--opacity takes a number from 0 to 1, not \"$value\""
        keys[backgroundOpacity]=$value
        say "Opacity: $value"
    fi

    if [[ -n ${look[wallpaper]:-} ]]; then
        if [[ ${look[wallpaper]} == default ]]; then
            unset 'keys[wallpaper]'
            drop_wallpapers
            say "Wallpaper: the theme's"
        else
            picture=${look[wallpaper]}
            [[ -f $picture && -r $picture ]] || die "can't read $picture"
            ext=${picture##*.}
            ext=${ext,,}
            [[ $ext =~ ^(jpg|jpeg|png|webp)$ ]] || die "the wallpaper must be a jpg, png or webp file"
            if [[ $ext == webp && ! -e /usr/lib/qt6/plugins/imageformats/libqwebp.so ]]; then
                warn "webp needs qt6-imageformats, or the greeter shows no wallpaper"
            fi
            # The greeter (user sddm) can't read your home: keep a copy here
            copy=$data/wallpaper.$ext
            if ((dry)); then
                printf '   [dry-run] copy %s to %s\n' "$picture" "$copy"
            else
                put "$copy" <"$picture"
            fi
            drop_wallpapers "$copy"
            keys[wallpaper]=$copy
            say "Wallpaper: a copy of $picture"
        fi
    fi

    {
        echo "[General]"
        echo "# Written by lyne-sddm: manual choices ($cmd --help). lyne-dots leaves"
        echo "# it alone while its sync is off; $cmd --reset goes back to the defaults."
        for key in preset "${palette[@]}" backgroundOpacity layout wallpaper; do
            if [[ -n ${keys[$key]:-} ]]; then echo "$key=${keys[$key]}"; fi
        done
    } | put "$file"
    if ((dry)); then
        say "Dry run: nothing was changed"
    else
        say "Done: it shows on the next login screen. Preview: sddm-greeter-qt6 --test-mode --theme $theme_dir"
    fi
    exit 0
fi

((dry)) && say "Dry run: nothing will be changed"

# ============================================================================
# UNINSTALL
# ============================================================================
if ((uninstall)); then
    if [[ ! -e $dest && ! -e $conf && ! -e $data ]]; then
        say "lyne-sddm is not installed"
        exit 0
    fi

    if ((packaged)) && [[ ! -e $conf && ! -e $data && ! -e $old_data ]]; then
        say "Nothing to remove: no $conf nor $data"
        exit 0
    fi

    after=$(effective_theme 0)
    after_theme=${after%%|*}
    say "After removal SDDM uses $(describe "$after")"
    if [[ -n $after_theme && ! -d $themes/$after_theme ]]; then
        warn "theme \"$after_theme\" is not installed: SDDM falls back to its default"
    fi
    [[ -e $data ]] && say "The synced files in $data (copies from lyne-dots) go too"

    say "Removing $conf"
    root rm -f "$conf"
    say "Removing $data"
    root rm -rf "$data"
    [[ -e $old_data ]] && root rm -rf "$old_data"
    if ((packaged)); then
        say "The theme itself stays: pacman -R lyne-sddm-git"
    else
        say "Removing $dest"
        root rm -rf "$dest"
    fi
    say "Done. SDDM was not restarted: the change shows on the next login screen"
    exit 0
fi

# ============================================================================
# INSTALL / UPDATE
# ============================================================================
if ((packaged)); then
    [[ -f $dest/metadata.desktop ]] || die "theme not found in $dest: install lyne-sddm-git first"
    theme_conf=$dest/theme.conf
else
    # pacman would fight over files a package owns
    if [[ -z $prefix ]] && command -v pacman >/dev/null &&
        package=$(pacman -Qqo "$dest/Main.qml" 2>/dev/null); then
        die "$dest belongs to the $package package: update it with pacman and run lyne-sddm for the setup"
    fi
    theme_conf=$src/theme.conf
fi
id "$owner" &>/dev/null || die "no such user: $owner"
group=$(id -gn "$owner")

command -v sddm-greeter-qt6 >/dev/null ||
    warn "sddm-greeter-qt6 not found: the theme needs SDDM built with Qt6"

# The greeter runs as the sddm user: only system fonts reach it
font=$(sed -n 's/^font=//p' "$theme_conf" | tail -1)
system_fonts=$(fc-list : file family | grep -E "^/usr/(share|local/share)/fonts/" || true)
if [[ $system_fonts != *"$font"* ]]; then
    warn "font \"$font\" is not in /usr/share/fonts: the greeter can't use it"
    warn "on Arch: sudo pacman -S ttf-cascadia-code-nerd"
fi

# Older versions kept the synced files inside the theme. Not copied over:
# `lyne sddm apply` in lyne-dots writes them again
migrated=0
if [[ -e $old_data ]]; then
    say "Removing the old synced dir $old_data (now $data)"
    root rm -rf "$old_data"
    migrated=1
fi

if ((packaged)); then
    say "Theme files: $dest (from the package)"
elif [[ -d $dest ]]; then
    say "Updating $dest"
    root find "$dest" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
else
    say "Installing to $dest"
    root install -d -m 755 "$dest"
fi

# Theme files, without any theme.conf.user or user/ left from testing
if ((packaged)); then
    :
elif ((dry)); then
    (cd "$src" && find . -type f ! -path './user/*' ! -name theme.conf.user | sort) |
        sed "s|^\./|   [dry-run] copy $dest/|"
else
    tar -C "$src" --exclude=./theme.conf.user --exclude=./user -cf - . |
        root tar -C "$dest" --no-same-owner --no-same-permissions -xf -
    root chmod -R u=rwX,go=rX "$dest"
fi

say "Synced files: $data (owned by $owner)"
if [[ -n $prefix ]]; then
    root install -d -m 755 "$data"
else
    # One owner per machine: running this as another user hands it over
    if [[ -d $data && $(stat -c %U "$data") != "$owner" ]]; then
        say "It belonged to $(stat -c %U "$data"): $owner controls the login screen now"
    fi
    root install -d -m 755 -o "$owner" -g "$group" "$data"
    root chown -R "$owner:$group" "$data"
fi
as_owner install -d -m 755 "$data/avatars"
# The empty template (default_conf), unless there is one already
if [[ ! -e $data/theme.conf.user ]]; then
    default_conf | write_file owner "$data/theme.conf.user" 644
fi
# The package ships this link already
((packaged)) || root ln -sfn "$data/theme.conf.user" "$dest/theme.conf.user"

say "Selecting the theme in $conf"
root install -d -m 755 "$confdir"
write_file root "$conf" 644 <<EOF
# Written by lyne-sddm; "$cmd --uninstall" removes it
[Theme]
Current=$name
EOF

result=$(effective_theme 1)
if [[ ${result%%|*} != "$name" ]]; then
    warn "$(describe "$result") is read after $conf and overrides it"
    warn "remove that Current= line for lyne to show"
fi

say "Done. SDDM was not restarted: the theme shows on the next login screen"
if ((migrated)); then
    say "Run 'lyne sddm apply' in lyne-dots to sync your look again"
fi
if ((packaged)); then
    say "Try it now: sddm-greeter-qt6 --test-mode --theme $dest"
else
    say "Try it now: ./test.sh -t $dest"
fi

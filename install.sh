#!/usr/bin/env bash
# Install lyne-sddm system-wide, update it, or remove it. Never restarts SDDM.
#
#   ./install.sh --dry-run               # show every step, change nothing
#   ./install.sh                         # install or update, and select it
#   ./install.sh --uninstall --dry-run
#   ./install.sh --uninstall             # remove it and its sddm.conf.d file
#   ./install.sh --user NAME             # owner of the synced files (default: you)
#
# theme/ goes to /usr/share/sddm/themes/lyne (root-owned). Inside it, user/
# belongs to you: lyne-dots writes theme.conf.user, the wallpaper and the
# avatars there without sudo (theme.conf.user in the theme root is a symlink
# to it). /etc/sddm.conf.d/lyne.conf selects the theme; removing it brings
# back whatever the other SDDM config files select.
#
# The lyne-sddm-git package installs this script as `lyne-sddm`. Without a
# theme/ dir next to it, it leaves the theme files to pacman and only sets up
# user/ and lyne.conf (--uninstall removes just those).
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
dry=0
uninstall=0
owner=${SUDO_USER:-$USER}
# Run from the package: the theme files belong to pacman
packaged=0
[[ -f $src/metadata.desktop ]] || packaged=1

usage() {
    sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

while (($#)); do
    case $1 in
    -n | --dry-run) dry=1 ;;
    -u | --uninstall) uninstall=1 ;;
    --user)
        owner=${2:?--user needs a name}
        shift
        ;;
    -h | --help) usage ;;
    *) usage 1 ;;
    esac
    shift
done

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die() {
    printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
    exit 1
}

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

# Writes stdin to a file as root: root_write PATH MODE [OWNER:GROUP]
root_write() {
    local path=$1 mode=$2 own=${3:-root:root} content
    content=$(cat)
    if ((dry)); then
        printf '   [dry-run] write %s (%s, %s):\n' "$path" "$mode" "$own"
        printf '%s\n' "$content" | sed 's/^/   [dry-run]   | /'
        return
    fi
    if [[ -n $prefix ]]; then
        printf '%s\n' "$content" | install -m "$mode" /dev/stdin "$path"
    else
        printf '%s\n' "$content" | root install -m "$mode" -o "${own%:*}" -g "${own#*:}" /dev/stdin "$path"
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

((dry)) && say "Dry run: nothing will be changed"

# ============================================================================
# UNINSTALL
# ============================================================================
if ((uninstall)); then
    if [[ ! -e $dest && ! -e $conf ]]; then
        say "lyne-sddm is not installed"
        exit 0
    fi

    if ((packaged)) && [[ ! -e $conf && ! -e $dest/user ]]; then
        say "Nothing to remove: no $conf nor $dest/user"
        exit 0
    fi

    after=$(effective_theme 0)
    after_theme=${after%%|*}
    say "After removal SDDM uses $(describe "$after")"
    if [[ -n $after_theme && ! -d $themes/$after_theme ]]; then
        warn "theme \"$after_theme\" is not installed: SDDM falls back to its default"
    fi
    [[ -d $dest/user ]] && say "The synced files in $dest/user (copies) go too"

    say "Removing $conf"
    root rm -f "$conf"
    if ((packaged)); then
        say "Removing $dest/user (the theme itself stays: pacman -R lyne-sddm-git)"
        root rm -rf "$dest/user"
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

if ((packaged)); then
    say "Theme files: $dest (from the package)"
elif [[ -d $dest ]]; then
    say "Updating $dest (keeping user/)"
    root find "$dest" -mindepth 1 -maxdepth 1 ! -name user ! -name theme.conf.user -exec rm -rf {} +
else
    say "Installing to $dest"
    root install -d -m 755 "$dest"
fi

# Theme files, without any local theme.conf.user or user/ from testing
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

say "Synced files: $dest/user (owned by $owner)"
if [[ -n $prefix ]]; then
    root install -d -m 755 "$dest/user" "$dest/user/avatars"
else
    root install -d -m 755 -o "$owner" -g "$group" "$dest/user" "$dest/user/avatars"
fi
if [[ ! -e $dest/user/theme.conf.user ]]; then
    root_write "$dest/user/theme.conf.user" 644 "$owner:$group" <<'EOF'
[General]
# Overrides of theme.conf, written by lyne-dots (see docs/sync.md).
# Empty: the theme's defaults (Tokyo Night).
EOF
fi
# The package ships this link already
((packaged)) || root ln -sfn user/theme.conf.user "$dest/theme.conf.user"

say "Selecting the theme in $conf"
root install -d -m 755 "$confdir"
root_write "$conf" 644 <<EOF
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
if ((packaged)); then
    say "Try it now: sddm-greeter-qt6 --test-mode --theme $dest"
else
    say "Try it now: ./test.sh -t $dest"
fi

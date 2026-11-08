# lyne-sddm

An SDDM theme for [lyne-dots](https://github.com/caioax/lyne-dots): the login
screen as a sibling of the Quickshell lock screen, with the same clock, fonts,
password pill and animations.

## Features

- Eight layouts: three from the lock screen's templates, `center` (clock
  and password in the middle), `cards` (users, clock and session as glass
  cards) and `wallpaper` (sharp wallpaper, the password bar rises as you
  type), and five of its own: `split` (a side panel), `focus` (only a big
  clock until you type), `corner` (clock and login card in opposite
  corners), `stacked` (huge hours over minutes) and `panel` (a top bar)
- Clock and date over the blurred wallpaper
- Avatar, user switcher and session picker
- Password field with animated error and a Caps Lock warning
- Suspend, reboot and shut down, with a cancellable countdown
- Light and dark palettes
- Works standalone (Tokyo Night by default) and follows the lyne-dots theme
  once synced

## Requirements

- SDDM 0.21+ built with Qt6 (`sddm` on Arch)
- `ttf-cascadia-code-nerd` (the greeter only sees fonts in `/usr/share/fonts`)

## Install

### Script

```sh
git clone https://github.com/caioax/lyne-sddm && cd lyne-sddm
./install.sh --dry-run    # see every step first
./install.sh              # install or update (asks for sudo)
```

It copies `theme/` to `/usr/share/sddm/themes/lyne`, creates
`/var/lib/lyne-sddm` owned by you (see below) and selects the theme in
`/etc/sddm.conf.d/lyne.conf`. A `Current=` in a config file read after that
one (or in `/etc/sddm.conf`) still wins: the installer warns about it. SDDM is
never restarted; the theme shows on the next login screen.

The installed theme is a copy: after `git pull` or any change to `theme/`,
run `./install.sh` again (no commit needed; `./test.sh` previews it first).

```sh
./install.sh --uninstall --dry-run
./install.sh --uninstall  # SDDM goes back to the theme the other files select
```

### Package (Arch)

`lyne-sddm-git` is not on the AUR yet; until it is, build it from a clone:

```sh
git clone https://github.com/caioax/lyne-sddm && cd lyne-sddm
makepkg -si               # builds lyne-sddm-git from GitHub
lyne-sddm --dry-run       # then, as your user: see the setup steps
lyne-sddm                 # create your synced dir and select the theme (asks for sudo)
```

pacman owns the theme files; `lyne-sddm` (this repo's `install.sh`) only adds
what a package can't know: `/var/lib/lyne-sddm` owned by you and
`/etc/sddm.conf.d/lyne.conf`. `lyne-sddm --uninstall` undoes that, and
removing the package cleans both up too. Updates: see [Updating](#updating).

Use one or the other: `install.sh` refuses to touch a theme pacman owns. To
switch to the script, `sudo pacman -R lyne-sddm-git` first (it removes
`/var/lib/lyne-sddm` too), then `./install.sh` and `lyne sddm apply`.

### Updating

| Installed with | Update |
| --- | --- |
| the script | `git pull && ./install.sh` in the clone |
| the package, built from a clone | `git pull && makepkg -si` in the clone |
| lyne-dots (`lyne sddm install`) | `lyne update` rebuilds it when there is a new version |

The package builds from GitHub, so `makepkg -si` alone already takes the
latest commit; `git pull` matters when the PKGBUILD itself changed. pacman
can't tell you about new versions until the package is on the AUR (then
`yay -Syu --devel` covers it). An update keeps `/var/lib/lyne-sddm` and
your choices: no need to run `lyne-sddm` again.

### Syncing with lyne-dots

To follow the lyne-dots palette, wallpaper and avatar, lyne-dots writes into
`/var/lib/lyne-sddm`, owned by you: `lyne sddm apply` (run by the shell on
every theme, wallpaper or avatar change) and `lyne sddm status`, or
Settings › Theme › Login screen. These need no reinstall. See
[docs/sync.md](docs/sync.md).

Coming from a version that kept the synced files in the theme's `user/`
dir: run the installer again (it removes that dir), then `lyne sddm apply` in
lyne-dots. Until then the theme shows its defaults.

## Several users

A machine has one login screen, so one look: the owner of
`/var/lib/lyne-sddm` (whoever ran `install.sh` or `lyne-sddm` last) sets it
for everyone, through their lyne-dots. Only that user's avatar is synced; the others show
their account icon (AccountsService) or a silhouette. Running the installer as
another user hands the dir, and the look, over to them.

## Testing

Run the greeter in test mode without touching the system; it takes a
screenshot of each monitor with `grim` (needs Hyprland, `jq` and `grim`):

```sh
./test.sh             # screenshots go to screenshots/
./test.sh -k          # keep it open after the shots
./test.sh -c my.conf  # try a theme.conf.user (palette, light mode...)
./test.sh -a face.png # with this avatar
./test.sh -D dir      # with a synced dir (its theme.conf.user and avatars)
./test.sh -t /usr/share/sddm/themes/lyne   # the installed theme
./test.sh -s keys:a,b,Return -s wait:1 -s shot:failed   # scripted keys
./test.sh -h
```

`test.sh` turns on `testMode`: every power button shows and does nothing,
and logins fail unless the password is `test`.

## Keys

| Key | Action |
| --- | --- |
| Enter | Log in (or pick the highlighted session) |
| Esc | Close the session list, cancel a power action, clear the password |
| F1 | Session list (↑ ↓ to move) |
| F2 | Next user |
| F10 / F11 / F12 | Suspend / reboot / shut down (press again to run) |

## Configuration

Every color and size comes from `theme/theme.conf` (see the comments
there); light and dark are just palettes, with no separate mode switch.
Overrides go in `/var/lib/lyne-sddm/theme.conf.user`: SDDM reads it on top
of `theme.conf` (through a symlink in the theme dir), and it is the file
lyne-dots writes when syncing.

The layout is the `layout` key (`center`, `cards`, `wallpaper`, `split`,
`focus`, `corner`, `stacked` or `panel`; anything else shows `center`):

```ini
[General]
layout=cards
```

### Without lyne-dots

`lyne-sddm` (or `./install.sh` from a clone) sets the look for you, no
sudo needed. Options combine and keep the earlier choices:

```sh
lyne-sddm --list-presets                # nord, gruvbox, rose-pine... (the lyne-dots palettes)
lyne-sddm --list-layouts
lyne-sddm --preset nord --layout cards
lyne-sddm --wallpaper ~/Pictures/pic.jpg  # copied in: the greeter can't read your home
lyne-sddm --opacity 0.8                 # cards and pills
lyne-sddm --wallpaper default            # back to the theme's wallpaper
lyne-sddm --reset                       # back to every default
```

They write `/var/lib/lyne-sddm/theme.conf.user`, so the install must have
run once. While the lyne-dots sync is on, lyne-dots owns that file and these
options refuse to touch it; with the sync off, lyne-dots leaves your choices
alone. `./test.sh -c theme/presets/nord.conf` previews a preset without
changing anything.

## License

[GPL-3.0](LICENSE), same as lyne-dots.

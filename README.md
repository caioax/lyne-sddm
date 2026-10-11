# lyne-sddm

An SDDM theme for [lyne-dots](https://github.com/caioax/lyne-dots): the login
screen as a sibling of the Quickshell lock screen, with the same clock, fonts,
password pill and animations.

> Work in progress.

## Features

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

### Package (Arch)

```sh
makepkg -si               # from a clone, builds lyne-sddm-git from GitHub
lyne-sddm --dry-run       # then, as your user: see the setup steps
lyne-sddm                 # create your synced dir and select the theme (asks for sudo)
```

pacman owns the theme files; `lyne-sddm` (this repo's `install.sh`) only adds
what a package can't know: `/var/lib/lyne-sddm` owned by you and
`/etc/sddm.conf.d/lyne.conf`. `lyne-sddm --uninstall` undoes that, and
removing the package cleans both up too.

Coming from a version that kept the synced files in the theme's `user/`
dir: run `lyne-sddm` again (it removes that dir), then `lyne sddm apply` in
lyne-dots. Until then the theme shows its defaults.

### Script

```sh
./install.sh --dry-run    # see every step first
./install.sh              # install or update (asks for sudo)
```

It copies `theme/` to `/usr/share/sddm/themes/lyne` and selects it in
`/etc/sddm.conf.d/lyne.conf`. A `Current=` in a config file read after that
one (or in `/etc/sddm.conf`) still wins: the installer warns about it. SDDM is
never restarted; the theme shows on the next login screen.

```sh
./install.sh --uninstall --dry-run
./install.sh --uninstall  # SDDM goes back to the theme the other files select
```

To follow the lyne-dots palette, wallpaper and avatar, lyne-dots writes into
`/var/lib/lyne-sddm`, owned by you: `lyne sddm apply` (run by the shell on
every theme, wallpaper or avatar change) and `lyne sddm status`, or
Settings › Theme › Login screen. See [docs/sync.md](docs/sync.md).

## Several users

A machine has one login screen, so one look: the owner of
`/var/lib/lyne-sddm` (whoever ran `lyne-sddm` last) sets it for everyone,
through their lyne-dots. Only that user's avatar is synced; the others show
their account icon (AccountsService) or a silhouette. Running `lyne-sddm` as
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

## License

[GPL-3.0](LICENSE), same as lyne-dots.

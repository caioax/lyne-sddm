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

## Testing

Run the greeter in test mode without touching the system; it takes a
screenshot of each monitor with `grim` (needs Hyprland, `jq` and `grim`):

```sh
./test.sh             # screenshots go to screenshots/
./test.sh -k          # keep it open after the shots
./test.sh -c my.conf  # try a theme.conf.user (palette, light mode...)
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
there); light and dark are just palettes, with no separate mode switch. Put
your overrides in `theme.conf.user` next to it: SDDM reads it on top of
`theme.conf`, and it is the file lyne-dots writes when syncing its palette.

## License

[GPL-3.0](LICENSE), same as lyne-dots.

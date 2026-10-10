# Syncing with lyne-dots

The theme works on its own (Tokyo Night). To follow lyne-dots, lyne-dots
writes into the theme's `user/` directory, which `install.sh` (`lyne-sddm`)
gives to the user, so no sudo is needed:

```
/usr/share/sddm/themes/lyne/
├── theme.conf.user -> user/theme.conf.user
└── user/                     owned by the user, 755
    ├── theme.conf.user       overrides of theme.conf
    ├── wallpaper.<ext>       copy of the current wallpaper
    └── avatars/<user>.png    copy of the profile picture
```

The greeter runs as the `sddm` user: it can't read `~`, so everything it
shows must be copied here (world-readable), never linked to the home dir.

## Who syncs

lyne-dots does, in its `SddmService` and the `lyne sddm` command:

- `lyne sddm apply` writes everything below; the shell runs it on each
  theme, wallpaper, avatar or background opacity change.
- `lyne sddm status` tells whether the theme is installed, selected and
  synced.
- Settings › Theme › Login screen turns the sync on and off.

## theme.conf.user

Synced, it looks like this:

```ini
[General]
# Written by lyne-dots (lyne sddm), edits here are lost.
background=#1a1b26
surface0=#24283b
# ...every key of the palette...
backgroundOpacity=0.9
wallpaper=user/wallpaper.jpeg
```

- **Palette**: the `palette` object of `~/.cache/lyne/nvim.json`, one
  `key=value` per entry. That file holds the applied palette in every mode,
  auto (matugen) included. All of it is written; the theme reads
  `background`, `surface0`..`surface3`, `text`, `textReverse`, `subtext`,
  `accent`, `success`, `warning`, `error` and `muted`, and ignores the rest
  (`subtextReverse`, `greyBlue`, `blueDark`...).
- **backgroundOpacity**: `opacity.background` of the lyne-dots
  `state.json`, in every mode (auto included). In lyne-dots it is a user
  preference (Settings › Layout); a theme only sets its starting value.
- **wallpaper**: path relative to the theme dir. Without it the theme's
  default wallpaper shows.
- Any other token of `theme.conf` can be overridden the same way. Quote
  values that contain a comma (`dateFormat="dddd, d MMMM"`), or SDDM reads
  them as a list.

### Sync off

Turning the sync off puts back the file `install.sh` creates, word for word,
and removes `user/wallpaper.*` and `user/avatars/<user>.png`:

```ini
[General]
# Overrides of theme.conf, written by lyne-dots (see docs/sync.md).
# Empty: the theme's defaults (Tokyo Night).
```

lyne-dots writes this text itself: when changing it in `install.sh`, change
it in lyne-dots too.

## Files

- **Wallpaper**: copied to `user/wallpaper.<ext>` keeping its extension
  (jpg, jpeg, png; webp needs `qt6-imageformats`), with `wallpaper=`
  pointing at it. The old copy goes when the extension changes.
- **Avatar**: copied to `user/avatars/<user>.png` as is, without converting:
  Qt picks the decoder from the content when the extension doesn't match
  (a jpg named `.png` loads fine). Without it the greeter tries the account
  icon, then a silhouette.

Each file is written to a temp name inside `user/` and moved into place, so
the greeter never reads half a file. Changes show on the next login screen;
nothing needs restarting.

# Syncing with lyne-dots

The theme works on its own (Tokyo Night). To follow lyne-dots, a sync step in
lyne-dots writes into the theme's `user/` directory, which `install.sh` gives
to the user, so no sudo is needed:

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

## theme.conf.user

```ini
[General]
background=#1a1b26
surface0=#24283b
# ...every key of the palette...
backgroundOpacity=0.9
wallpaper=user/wallpaper.jpg
```

- **Palette**: the `palette` object of `~/.cache/lyne/nvim.json`, one
  `key=value` per entry. That file holds the applied palette in every mode,
  auto (matugen) included. Keys the theme doesn't use are ignored.
- **backgroundOpacity**: `opacity.background` of the theme JSON
  (`~/.local/themes/<name>.json`) when there is one; `nvim.json` doesn't
  carry it, so leave it out in auto mode (the default, 0.9, applies).
- **wallpaper**: path relative to the theme dir. Omit it to keep the theme's
  default wallpaper.
- Any other token of `theme.conf` can be overridden the same way. Quote
  values that contain a comma (`dateFormat="dddd, d MMMM"`), or SDDM reads
  them as a list.

## Files

- **Wallpaper**: copy the current one to `user/wallpaper.<ext>`, keeping its
  extension (jpg, png; webp needs `qt6-imageformats`), and point `wallpaper=`
  at it. Remove the old copy when the extension changes.
- **Avatar**: copy the profile picture to `user/avatars/<user>.png`. Without
  it the greeter tries the account icon, then a silhouette.

Write each file to a temp name inside `user/` and `mv` it into place, so the
greeter never reads half a file. Changes show on the next login screen;
nothing needs restarting.

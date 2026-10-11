# Syncing with lyne-dots

The theme works on its own (Tokyo Night). To follow lyne-dots, lyne-dots
writes into `/var/lib/lyne-sddm`, which `install.sh` (`lyne-sddm`) creates
and gives to the user, so no sudo is needed:

```
/var/lib/lyne-sddm/           owned by the user, 755 (the theme's dataDir)
├── theme.conf.user           overrides of theme.conf
├── wallpaper.<ext>           copy of the current wallpaper
└── avatars/<user>.png        copy of the profile picture

/usr/share/sddm/themes/lyne/  owned by root (pacman or install.sh)
└── theme.conf.user -> /var/lib/lyne-sddm/theme.conf.user
```

SDDM only reads `theme.conf.user` next to `theme.conf`, hence the symlink;
lyne-dots never touches it, nor anything else under `/usr`. Until
`lyne-sddm` runs, the link dangles and the theme shows its defaults.

The greeter runs as the `sddm` user: it can't read `~`, so everything it
shows must be copied here (world-readable, 644), never linked to the home
dir.

The path is the `dataDir` token of `theme.conf`, where the theme looks for
avatars. lyne-dots uses `/var/lib/lyne-sddm` and nothing else (no fallback
to the old `user/` dir); its `LYNE_SDDM_DIR` variable points it elsewhere
for tests, and `./test.sh -D <dir>` shows such a dir in the greeter.

## Who syncs

lyne-dots does, in its `SddmService` and the `lyne sddm` command:

- `lyne sddm apply` writes everything below; the shell runs it on each
  theme, wallpaper, avatar or background opacity change.
- `lyne sddm status` tells whether the theme is installed, selected and
  synced, and whether `/var/lib/lyne-sddm` exists and is writable (if not:
  run `lyne-sddm`); `apply` fails with the same message. "Installed" means
  `/usr/share/sddm/themes/lyne/metadata.desktop` exists: keep that file and
  its path.
- The selected theme is the last `Current=` read from
  `/usr/lib/sddm/sddm.conf.d`, `/etc/sddm.conf.d` and `/etc/sddm.conf`.
- Settings › Theme › Login screen turns the sync on and off.

## Who creates and removes the dir

lyne-sddm, never lyne-dots:

- `lyne-sddm` creates `/var/lib/lyne-sddm` and `avatars/` owned by the user
  who runs it, and the empty `theme.conf.user` below if there is none. Run
  by another user, it hands the dir over to them.
- lyne-dots never creates the dir; it only recreates `avatars/` (755) when
  the dir is its own and that subdir went missing.
- `lyne-sddm` deletes the old `/usr/share/sddm/themes/lyne/user/` dir of earlier
  versions without copying anything: `lyne sddm apply` writes it all again.
- `lyne-sddm --uninstall` and removing the package delete
  `/var/lib/lyne-sddm`.

## theme.conf.user

Synced, it looks like this:

```ini
[General]
# Written by lyne-dots (lyne sddm), edits here are lost.
background=#1a1b26
surface0=#24283b
# ...every key of the palette...
backgroundOpacity=0.9
wallpaper=/var/lib/lyne-sddm/wallpaper.jpeg
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
- **wallpaper**: absolute path of the copy (inside the synced dir in use).
  Without it the theme's default wallpaper shows.
- **dataDir** is never written: it belongs to `theme.conf`.
- Any other token of `theme.conf` can be overridden the same way. Quote
  values that contain a comma (`dateFormat="dddd, d MMMM"`), or SDDM reads
  them as a list.

### Sync off

Turning the sync off puts back the file `install.sh` creates, word for word,
and removes `wallpaper.*` and `avatars/<user>.png`:

```ini
[General]
# Overrides of theme.conf, written by lyne-dots (see docs/sync.md).
# Empty: the theme's defaults (Tokyo Night).
```

lyne-dots writes this text itself: when changing it in `install.sh`, change
it in lyne-dots too.

## Files

- **Wallpaper**: copied to `wallpaper.<ext>` keeping its extension (jpg,
  jpeg, png; webp needs `qt6-imageformats`), with `wallpaper=` pointing at
  it. The old copy goes when the extension changes.
- **Avatar**: copied to `avatars/<user>.png` as is, without converting: Qt
  picks the decoder from the content when the extension doesn't match (a
  jpg named `.png` loads fine). Without it the greeter tries the account
  icon, then a silhouette.

Each file is written to a temp name inside the synced dir and moved into
place, so the greeter never reads half a file. Changes show on the next
login screen; nothing needs restarting.

## Several users

There is one login screen per machine, so one synced dir: its owner's
lyne-dots sets the look everyone sees. Only the owner's avatar is synced;
other users get their account icon (AccountsService) or the silhouette.

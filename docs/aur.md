# Publishing on the AUR

`lyne-sddm-git` builds from the latest commit on GitHub. The AUR keeps a
small git repo of its own with only the packaging files:

```
ssh://aur@aur.archlinux.org/lyne-sddm-git.git   (branch master)
├── PKGBUILD
├── lyne-sddm.install
└── .SRCINFO          generated from PKGBUILD, read by the AUR website and helpers
```

This repo stays the source of truth: change `PKGBUILD` and
`lyne-sddm.install` here, then copy them over. The AUR only needs a push
when one of them changes, not on every commit: helpers rebuild -git
packages from GitHub (`yay -Syu --devel`).

## Once

1. Create an account at <https://aur.archlinux.org/register>.
2. SSH key just for the AUR, and its host entry:

   ```sh
   ssh-keygen -t ed25519 -f ~/.ssh/aur -C aur
   cat >>~/.ssh/config <<'EOF'
   Host aur.archlinux.org
     IdentityFile ~/.ssh/aur
     User aur
   EOF
   ```

3. Paste `~/.ssh/aur.pub` into My Account › SSH Public Key.
4. Check: `ssh aur@aur.archlinux.org help` lists the AUR commands.

## Checking a release

Tag it so `pkgver` starts from the version (`0.1.0.r3.g1234abc`: 3 commits
after v0.1.0):

```sh
git tag -a v0.1.0 -m "lyne-sddm 0.1.0"
git push origin v0.1.0
```

Build in a clean chroot: it catches dependencies missing from `depends`
that your system happens to have. It asks for sudo, and builds from GitHub,
so push first:

```sh
dir=$(mktemp -d)
cp PKGBUILD lyne-sddm.install "$dir" && cd "$dir"
extra-x86_64-build
namcap PKGBUILD lyne-sddm-git-*.pkg.tar.zst
```

Expected from namcap, all harmless:

- `E: Symlink (usr/share/sddm/themes/lyne/theme.conf.user) points to
  non-existing /var/lib/lyne-sddm/theme.conf.user`: `lyne-sddm` creates
  the target; until then the theme uses its defaults (docs/sync.md).
- `W: Dependency included, but may not be needed` for `sudo`, `sddm` and
  `ttf-cascadia-code-nerd`: used by `lyne-sddm` and the theme's QML, which
  namcap doesn't read.

Then install the built package and run `lyne-sddm` and `./test.sh -t
/usr/share/sddm/themes/lyne` before publishing.

## First push

Cloning a name nobody owns gives an empty repo; the first push creates
the package, owned by you:

```sh
git clone https://aur.archlinux.org/lyne-sddm-git.git ~/Dev/aur/lyne-sddm-git
cd ~/Dev/aur/lyne-sddm-git
git remote set-url --push origin ssh://aur@aur.archlinux.org/lyne-sddm-git.git
git symbolic-ref HEAD refs/heads/master   # the AUR only takes master
cp ~/Dev/lyne-sddm/{PKGBUILD,lyne-sddm.install} .
makepkg --printsrcinfo >.SRCINFO
git add PKGBUILD lyne-sddm.install .SRCINFO
git commit -m "Initial import: lyne-sddm-git 0.1.0"
git push -u origin master   # first time; later just git push
```

The clone works without an account (read-only over https); pushes go over
SSH. `.SRCINFO` copies `pkgver` from the PKGBUILD as written, so set it
first to the one the chroot build printed (makepkg rewrites it there), and
keep the repo's PKGBUILD in step.

The page shows at <https://aur.archlinux.org/packages/lyne-sddm-git>, and
`yay -S lyne-sddm-git` works.

## Updates

When `PKGBUILD` or `lyne-sddm.install` change here:

1. Same pkgver (packaging-only change): bump `pkgrel`; a new tag or new
   commits reset it to 1. For -git packages pkgver only moves when
   makepkg runs, which is fine.
2. Copy both files into the AUR clone, run `makepkg --printsrcinfo
   >.SRCINFO` (always: the AUR rejects a push whose .SRCINFO is missing or
   stale), commit and push.

Every commit in the AUR repo is public history: no force pushes, and
messages that say what changed for users.

## Maintenance

- Read the comments on the package page; answer there or fix and push.
- "Flagged out-of-date" rarely applies to -git packages: unflag it if
  nothing needs changing.
- Want to stop? Disown the package on its page so someone else can adopt
  it.
- A stable `lyne-sddm` (tag tarball and checksums) can come later;
  `provides`/`conflicts` already let both coexist on the AUR.

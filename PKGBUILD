# Maintainer: caioax <acaio9677@gmail.com>
pkgname=lyne-sddm-git
_name=lyne-sddm
pkgver=r5.76890e8
pkgrel=1
pkgdesc='SDDM theme for lyne-dots, sibling of its Quickshell lock screen'
arch=('any')
url='https://github.com/caioax/lyne-sddm'
license=('GPL-3.0-only')
depends=('sddm' 'qt6-declarative' 'ttf-cascadia-code-nerd')
makedepends=('git')
optdepends=('qt6-imageformats: webp wallpapers')
provides=("$_name")
conflicts=("$_name")
install=lyne-sddm.install
source=("$_name::git+$url.git")
sha256sums=('SKIP')

pkgver() {
    cd "$_name"
    (
        set -o pipefail
        git describe --long --abbrev=7 2>/dev/null | sed 's/\([^-]*-g\)/r\1/;s/-/./g' ||
            printf 'r%s.%s' "$(git rev-list --count HEAD)" "$(git rev-parse --short=7 HEAD)"
    )
}

package() {
    cd "$_name"
    local dest="$pkgdir/usr/share/sddm/themes/lyne"

    install -d "$dest"
    cp -r --no-preserve=ownership,mode theme/. "$dest/"
    find "$dest" -type d -exec chmod 755 {} +
    find "$dest" -type f -exec chmod 644 {} +
    # SDDM only reads theme.conf.user next to theme.conf; the real file lives
    # in the user-owned dir that `lyne-sddm` creates (dangling until then)
    ln -s /var/lib/lyne-sddm/theme.conf.user "$dest/theme.conf.user"

    install -Dm755 install.sh "$pkgdir/usr/bin/lyne-sddm"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
    install -Dm644 README.md docs/sync.md -t "$pkgdir/usr/share/doc/$pkgname/"
}

# User AUR Packages

Workspace for user-specific AUR-style packages. Each package lives in its own folder with a `PKGBUILD` and any helper files needed to build locally or share with others.

## Packages

- `cursor` – Cursor IDE binary repack (`cursor-bin`)
- `signal` – Signal Desktop binary repack (`signal-desktop-bin`)
- `google-chrome` – Google Chrome binary repack (`google-chrome-bin`)
- `mullavad` – Mullvad VPN binary repack (`mullvad-vpn-bin`)

## PKGBUILD schema

Use this section order for each `PKGBUILD`. Mark unused sections with `# empty`.

```text
# shellcheck shell=bash disable=SC2034,SC2154

# Metadata
pkgname / pkgver / pkgrel / pkgdesc / arch / url / license

# Dependencies
depends and/or makedepends

# Relations
provides / conflicts

# Options
options, or: # empty

# Sources
private vars, source, noextract, sha256sums

# Build
build(), or: # empty

# Package
package()
```

Copy the closest existing package when adding one.

## Root Makefile

```bash
make pin PKG=cursor
make build PKG=cursor
make install PKG=cursor
make install
make checksum
make clean
make test
make
```

To update a package, change its version and source URL, then run:

```bash
make pin PKG=cursor
make build PKG=cursor
```

`pin` is `updpkgsums`. `checksum` is `makepkg --verifysource` when you want an explicit verify.
Bare `make` / `make install` go through `scripts/install.sh`, skip when the same version is already installed, and clean artifacts on exit or interrupt.
`FORCE=1` forces reinstall. `makepkg -si` validates checksums when it actually builds.
Needs `base-devel` and `pacman-contrib`.

## Build without make

```bash
cd cursor
makepkg -s
makepkg -si
```

## Redirect build artifacts

```bash
PKGDEST="$PWD/artifacts/pkg" SRCDEST="$PWD/artifacts/src" \
LOGDEST="$PWD/artifacts/logs" BUILDDIR="$PWD/artifacts/build" makepkg -Csi
```

Run this inside a package directory.

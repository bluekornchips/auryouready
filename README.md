# User AUR Packages

Workspace for user-specific AUR-style packages. Each package lives in its own folder with a `PKGBUILD` and any helper files needed to build locally or share with others.

## Packages

- `cursor` – Cursor IDE binary repack (`cursor-bin`)
- `signal` – Signal Desktop binary repack (`signal-desktop-bin`)
- `synology-drive-client` – Synology Drive Client repack (`synology-drive-client-bin`)
- `google-chrome` – Google Chrome binary repack (`google-chrome-bin`)
- `mullavad` – Mullvad VPN binary repack (`mullvad-vpn-bin`)
- `shfmt` – Shell parser/formatter (source build)

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
private vars, source, noextract, sha512sums

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
make build PKG=signal
make install PKG=synology-drive-client
make install PKG=google-chrome
make install PKG=mullavad
make install PKG=shfmt
make test
make checksum
make clean
```

To update a package, change its version and source URL, then run:

```bash
make pin PKG=cursor
make build PKG=cursor
```

`pin` needs `updpkgsums` from `pacman-contrib`. `checksum` only verifies existing sums.

## Requirements

Arch Linux with `base-devel` and `pacman-contrib`. Packages may list more build dependencies.

## Build a package

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

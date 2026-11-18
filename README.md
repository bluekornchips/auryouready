# User AUR Packages

Local `PKGBUILD` workspace for binary repacks on Arch Linux.

## Packages

- `cursor`: `cursor-bin`, Cursor IDE
- `signal`: `signal-desktop-bin`, Signal Desktop
- `google-chrome`: `google-chrome-bin`, Google Chrome
- `mullavad`: `mullvad-vpn-bin`, Mullvad VPN
- `synology-drive-client`: `synology-drive-client-bin`, Synology Drive Client

## Usage

Update all package definitions from upstream, then build and install any newer versions:

```bash
make update
make install
```

`make update` runs `scripts/update.sh` to query upstream, rewrite `pkgver` and `pkgrel` when newer, and refresh `sha256sums` with `updpkgsums`. Packages already at the latest version are skipped.

`make install` runs `scripts/install.sh` to build and install each package with `makepkg -si`, skipping packages whose installed version already matches `PKGBUILD`. Both targets clean build and download artifacts on exit.

Target one or more packages or run individual steps:

```bash
make update PKG=cursor
make install PKG=cursor
make install FORCE=1 PKG=cursor
make build PKG=cursor
make pin PKG=cursor
make checksum
make clean
make test
./scripts/update.sh -p cursor -p signal
```

`FORCE=1` reinstalls a matching version. `pin` runs `updpkgsums`, and `checksum` runs `makepkg --verifysource`.

Requires `base-devel`, `pacman-contrib`, and `curl`. `make test` also requires `shellcheck` and `bats`.

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

## Direct makepkg

Inside a package directory:

```bash
makepkg -si
```

Redirect build artifacts outside the package directory:

```bash
PKGDEST="$PWD/artifacts/pkg" SRCDEST="$PWD/artifacts/src" \
LOGDEST="$PWD/artifacts/logs" BUILDDIR="$PWD/artifacts/build" makepkg -Csi
```

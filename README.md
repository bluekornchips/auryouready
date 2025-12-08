# User AUR Packages

Workspace for user-specific AUR-style packages. Each package lives in its own folder with a `PKGBUILD` and any helper files needed to build locally or share with others.

## Layout

- `cursor-bin/PKGBUILD` – real package wrapping Cursor’s upstream deb while using system Electron.
- `examples/hello-world/PKGBUILD` – minimal starter; pairs with `examples/hello-world/hello.sh`.
- `signal-desktop-bin/PKGBUILD` – official Signal Desktop binary repack sourced from the upstream apt repository.

## Requirements

- Arch Linux (or derivative) with `base-devel`.
- Tools: `git`, `fakeroot`, `bsdtar`, `tar`, `curl`/`wget`, `pacman`.
- For binary repacks, enough disk space to unpack the upstream archive.

## Create a new package (fast path)

1. Copy the starter and enter it:

```
cp -r examples/hello-world my-package && cd my-package
```

2. Edit `PKGBUILD`: set `pkgname/pkgver/pkgdesc`, point `source` at your upstream files, add `depends`, and replace checksum placeholders with real values (run `makepkg -g` to regenerate, then paste the results).
3. Build and install locally:

```
makepkg -si
```

4. Clean build artifacts when done:

```
makepkg -C
```

## Redirect build artifacts per package

To keep build outputs under each package directory, run makepkg with per-invocation destinations:

```
PKGDEST="$PWD/artifacts/pkg" SRCDEST="$PWD/artifacts/src" \
LOGDEST="$PWD/artifacts/logs" BUILDDIR="$PWD/artifacts/build" makepkg -Csi
```

This keeps packages, sources, logs, and build trees inside `artifacts/` for the current package.

## Example: hello-world (starter)

- Installs a tiny `hello-world` script for reference.
- Uses `sha256sums=('SKIP')` for convenience; replace with real sums in production.

## Example: cursor-bin (clean)

- Minimal repack of the official Cursor deb with no extra shims.
- Build from `cursor-bin/`:

```
cd cursor-bin
makepkg -si
```

Confirm checksums before publishing.

## Example: signal-desktop-bin (Signal)

- Pulls the official `signal-desktop` deb from `updates.signal.org` with a pinned checksum.
- Build from `signal-desktop-bin/`:

```
cd signal-desktop-bin
makepkg -si
```

Upstream publishes Debian/Ubuntu instructions (add signing key, add the apt source, then `apt install signal-desktop`). This package consumes the same deb directly for Arch-style installations, so no extra repository setup is required. The checksum guards the download in place of the apt key step.

## Why keep this structure

- Reproducible: explicit sources and hashes.
- Secure: rely on system Electron and verified downloads.
- Maintainable: one folder per package; easy diffs and rebuilds.
- Shareable: drop a folder on another machine and run `makepkg`.

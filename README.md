# User AUR Packages

Workspace for user-specific AUR-style packages. Each package lives in its own folder with a `PKGBUILD` and any helper files needed to build locally or share with others.

## Packages

- `cursor-bin` – Cursor IDE binary repack
- `signal-desktop-bin` – Signal Desktop binary repack
- `synology-drive-client-bin` – Synology Drive Client repack
- `shfmt` – Shell parser/formatter (source build)

## Root Makefile

From the repository root, convenience targets wrap `makepkg -si` for some packages and run cleanup:

```bash
make help              # list targets
make clean             # remove makepkg outputs and downloaded .deb files under each package dir
make cursor
make signal
make synology-drive-client
make shfmt
```

`make clean` runs `cleanup.sh`, which clears `pkg` and `src` trees, package archives, signatures, makepkg logs, and downloaded `.deb` sources in every immediate subdirectory that contains a `PKGBUILD`.

You can also run cleanup directly:

```bash
./cleanup.sh --help
```

## Requirements

Arch Linux (or derivative) with `base-devel`. Tools: `git`, `fakeroot`, `bsdtar`, `tar`, `curl` or `wget`, `pacman`. Individual `PKGBUILD` files may list extra build dependencies.

## Build a package

```bash
cd cursor-bin   # or another package directory
makepkg -si
```

Or use the matching `make` target from the repo root, see above.

Adjust the copy source to a package closest to what you need, for example a `-bin` repack versus a source build like `shfmt`.

## Redirect build artifacts

```bash
PKGDEST="$PWD/artifacts/pkg" SRCDEST="$PWD/artifacts/src" \
LOGDEST="$PWD/artifacts/logs" BUILDDIR="$PWD/artifacts/build" makepkg -Csi
```

Run that from inside the package directory, or set the same variables when invoking `makepkg` from your shell profile for a global layout.

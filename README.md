# User AUR Packages

Workspace for user-specific AUR-style packages. Each package lives in its own folder with a `PKGBUILD` and any helper files needed to build locally or share with others.

## Packages

- `cursor-bin` – Cursor IDE binary repack
- `google-chrome-bin` – Google Chrome browser repack
- `google-antigravity-bin` – Google Antigravity binary repack
- `signal-desktop-bin` – Signal Desktop binary repack
- `synology-drive-client-bin` – Synology Drive Client repack
- `shfmt` – Shell parser/formatter (source build)
- `examples/hello-world` – Starter template

## Requirements

Arch Linux (or derivative) with `base-devel`. Tools: `git`, `fakeroot`, `bsdtar`, `tar`, `curl`/`wget`, `pacman`.

## Create a new package

```bash
cp -r examples/hello-world my-package && cd my-package
# Edit PKGBUILD, then:
makepkg -si
```

## Redirect build artifacts

```bash
PKGDEST="$PWD/artifacts/pkg" SRCDEST="$PWD/artifacts/src" \
LOGDEST="$PWD/artifacts/logs" BUILDDIR="$PWD/artifacts/build" makepkg -Csi
```

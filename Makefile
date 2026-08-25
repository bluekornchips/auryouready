PACKAGES := cursor signal google-chrome mullavad shfmt

.PHONY: build install pin test checksum clean all
.DEFAULT_GOAL := all

build:
	@test -n "$(PKG)" || { echo "usage: make build PKG=<package>"; exit 1; }
	cd "$(PKG)" && makepkg -s

install:
	@test -n "$(PKG)" || { echo "usage: make install PKG=<package>"; exit 1; }
	./scripts/install.sh --target "$(PKG)"

pin:
	@test -n "$(PKG)" || { echo "usage: make pin PKG=<package>"; exit 1; }
	./scripts/checksum.sh -u -t "$(PKG)"

test:
	command -v shellcheck >/dev/null || { echo "shellcheck is not installed"; exit 1; }
	command -v bats >/dev/null || { echo "bats is not installed"; exit 1; }
	shellcheck scripts/*.sh scripts/tests/*.sh
	shellcheck -s bash */PKGBUILD
	bats scripts/tests/*.sh --verbose-run --timing

checksum:
	./scripts/checksum.sh $(foreach pkg,$(PACKAGES),-t $(pkg))

clean:
	./scripts/cleanup.sh

all: checksum clean
	@trap '$(MAKE) clean' EXIT INT TERM; \
	for pkg in $(PACKAGES); do $(MAKE) install PKG="$$pkg" || exit 1; done

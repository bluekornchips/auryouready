PACKAGES := cursor signal google-chrome mullavad shfmt

.PHONY: build install pin test checksum clean all
.DEFAULT_GOAL := all

build:
	@test -n "$(PKG)" || { echo "usage: make build PKG=<package>"; exit 1; }
	cd "$(PKG)" && makepkg -s

install:
	@test -n "$(PKG)" || { echo "usage: make install PKG=<package>"; exit 1; }
	cd "$(PKG)" && makepkg -si

pin:
	@test -n "$(PKG)" || { echo "usage: make pin PKG=<package>"; exit 1; }
	./checksum.sh -u -t "$(PKG)"

test:
	command -v shellcheck >/dev/null || { echo "shellcheck is not installed"; exit 1; }
	command -v bats >/dev/null || { echo "bats is not installed"; exit 1; }
	shellcheck *.sh tests/*.sh
	shellcheck -s bash */PKGBUILD
	bats tests/*.sh --verbose-run --timing

checksum:
	./checksum.sh $(foreach pkg,$(PACKAGES),-t $(pkg))

clean:
	./cleanup.sh

all: checksum clean test
	@for pkg in $(PACKAGES); do $(MAKE) install PKG="$$pkg" || exit 1; done

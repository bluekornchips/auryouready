BIN_PACKAGES := cursor signal synology-drive-client google-chrome

.PHONY: build install pin test checksum clean all
.DEFAULT_GOAL := all

build:
	@test -n "$(PKG)" || { echo "usage: make build PKG=<package>"; exit 1; }
	cd $(PKG) && makepkg -s

install:
	@test -n "$(PKG)" || { echo "usage: make install PKG=<package>"; exit 1; }
	cd $(PKG) && makepkg -si

pin:
	@test -n "$(PKG)" || { echo "usage: make pin PKG=<package>"; exit 1; }
	./checksum.sh -u -t $(PKG)

test:
	shellcheck --version >/dev/null 2>&1 || (echo "shellcheck is not installed" && exit 1)
	bats --version >/dev/null 2>&1 || (echo "bats is not installed" && exit 1)
	shellcheck *.sh tests/*.sh
	shellcheck -s bash */PKGBUILD
	bats tests/*.sh --verbose-run --timing

checksum:
	./checksum.sh $(foreach t,$(BIN_PACKAGES),-t $(t))

clean:
	./cleanup.sh

all: checksum clean
	$(MAKE) install PKG=signal
	$(MAKE) install PKG=synology-drive-client
	$(MAKE) install PKG=cursor
	$(MAKE) install PKG=shfmt
	$(MAKE) install PKG=google-chrome

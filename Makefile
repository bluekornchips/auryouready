PACKAGES := cursor signal google-chrome mullavad
SELECTED := $(if $(strip $(PKG)),$(PKG),$(PACKAGES))
CLEAN_DIRS := $(foreach p,$(SELECTED),$(p)/pkg $(p)/src)
CLEAN_FILES := $(foreach p,$(SELECTED),$(p)/*.pkg.tar.* $(p)/*.deb $(p)/makepkg-*.log)

.PHONY: build install update pin test checksum clean all
.DEFAULT_GOAL := all

build:
	@test -n "$(PKG)" || { echo "usage: make build PKG=<package>"; exit 1; }
	cd "$(PKG)" && makepkg -s

install:
	@trap 'rm -rf $(CLEAN_DIRS); rm -f $(CLEAN_FILES)' EXIT INT TERM; \
	for pkg in $(SELECTED); do \
		./scripts/install.sh "$$pkg" || exit 1; \
	done

update:
	@trap 'rm -rf $(CLEAN_DIRS); rm -f $(CLEAN_FILES)' EXIT INT TERM; \
	./scripts/update.sh $(if $(PKG),-p $(PKG),)

pin:
	@test -n "$(PKG)" || { echo "usage: make pin PKG=<package>"; exit 1; }
	cd "$(PKG)" && updpkgsums --nocolor

checksum:
	@for pkg in $(SELECTED); do \
		(cd "$$pkg" && makepkg -f --verifysource --nocolor) || exit 1; \
	done

clean:
	@rm -rf $(CLEAN_DIRS)
	@rm -f $(CLEAN_FILES)

test:
	command -v shellcheck >/dev/null || { echo "shellcheck is not installed"; exit 1; }
	command -v bats >/dev/null || { echo "bats is not installed"; exit 1; }
	shellcheck scripts/*.sh scripts/packages/* scripts/tests/*.sh
	shellcheck -s bash */PKGBUILD
	bats scripts/tests/*.sh --verbose-run --timing

all: clean test install

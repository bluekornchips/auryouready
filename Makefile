BIN_PACKAGES := signal-desktop-bin synology-drive-client-bin
SHELL_FILES  := $(shell find . -name "*.sh" -type f)

.PHONY: checksum clean \
        signal synology-drive-client cursor shfmt

checksum:
	./checksum.sh $(foreach t,$(BIN_PACKAGES),-t $(t))

signal:
	cd signal-desktop-bin && makepkg -si

synology-drive-client:
	cd synology-drive-client-bin && makepkg -si

shfmt:
	cd shfmt && makepkg -si

clean:
	./cleanup.sh

all: checksum clean signal synology-drive-client shfmt
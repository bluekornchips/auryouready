BIN_PACKAGES := cursor signal-desktop synology-drive-client google-chrome
SHELL_FILES  := $(shell find . -name "*.sh" -type f)

.PHONY: checksum clean \
        signal synology-drive-client cursor shfmt google-chrome

checksum:
	./checksum.sh $(foreach t,$(BIN_PACKAGES),-t $(t))

signal:
	cd signal-desktop && makepkg -si

synology-drive-client:
	cd synology-drive-client && makepkg -si

cursor:
	cd cursor && makepkg -si

shfmt:
	cd shfmt && makepkg -si

google-chrome:
	cd google-chrome && makepkg -si

clean:
	./cleanup.sh

all: checksum clean signal synology-drive-client cursor shfmt google-chrome

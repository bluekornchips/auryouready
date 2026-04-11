.PHONY: clean help

help:
	@echo "Targets:"
	@echo "  clean  Remove makepkg output and downloaded .deb files under each */PKGBUILD directory"
	@echo "  help   Show this message"

clean:
	@bash "$(CURDIR)/cleanup.sh"

cursor:
	@bash -c 'cd cursor-bin && makepkg -si'

synology-drive-client:
	@bash -c 'cd synology-drive-client-bin && makepkg -si'

signal:
	@bash -c 'cd signal-desktop-bin && makepkg -si'

shfmt:
	@bash -c 'cd shfmt && makepkg -si'
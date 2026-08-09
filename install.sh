#!/usr/bin/env bash
# shellcheck shell=bash
#
# Build and install package PKGBUILDs.
#

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
	cat <<EOF
Usage: $(basename "$0") [OPTION]

Build and install a package. Ask before reinstalling the same version.

Options:
  -h, --help            Show this help and exit
  -t, --target PACKAGE  Package directory to install
EOF

	return 0
}

install_target() {
	local target="$1"

	[[ -f "${target}/PKGBUILD" ]] || {
		echo "install_target:: no PKGBUILD in ${target}" >&2
		return 1
	}

	local srcinfo
	srcinfo="$(cd "${target}" && makepkg --printsrcinfo)" || return 1

	local pkgname
	pkgname="$(awk '$1 == "pkgname" { print $3; exit }' <<<"${srcinfo}")"

	local epoch
	epoch="$(awk '$1 == "epoch" { print $3; exit }' <<<"${srcinfo}")"

	local pkgver
	pkgver="$(awk '$1 == "pkgver" { print $3; exit }' <<<"${srcinfo}")"

	local pkgrel
	pkgrel="$(awk '$1 == "pkgrel" { print $3; exit }' <<<"${srcinfo}")"

	local version
	version="${epoch:+${epoch}:}${pkgver}-${pkgrel}"

	local installed_version
	installed_version="$(pacman -Q "${pkgname}" 2>/dev/null | awk '{ print $2 }')" || true

	if [[ "${installed_version}" == "${version}" ]]; then
		local answer
		printf '%s is already installed at version %s. Reinstall? [y/N] ' \
			"${pkgname}" "${installed_version}"
		read -r answer || answer=""
		case "${answer}" in
		[yY] | [yY][eE][sS])
			;;
		*)
			echo "install_target:: install skipped"
			return 0
			;;
		esac
	fi

	(cd "${target}" && makepkg -si)
	return $?
}

main() {
	local target=""

	case "${1:-}" in
	-h | --help)
		usage
		return 0
		;;
	-t | --target)
		target="${2:-}"
		;;
	*)
		echo "main:: usage: $0 --target PACKAGE" >&2
		return 1
		;;
	esac

	[[ -n "${target}" ]] || {
		echo "main:: --target requires a package directory" >&2
		return 1
	}

	if ! command -v makepkg >/dev/null 2>&1; then
		echo "main:: makepkg is not installed" >&2
		return 1
	fi

	if ! command -v pacman >/dev/null 2>&1; then
		echo "main:: pacman is not installed" >&2
		return 1
	fi

	cd "${ROOT}" || return 1
	install_target "${target}"
	return $?
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -eo pipefail
	umask 077
	main "$@"
	exit $?
fi

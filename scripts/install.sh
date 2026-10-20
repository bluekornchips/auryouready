#!/usr/bin/env bash
# shellcheck shell=bash
#
# Build and install one package directory.
# Same version already installed: skip unless FORCE is set.
#

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Print usage to stdout.
#
# Outputs:
# - usage text
#
# Returns:
# - 0 always
usage() {
	cat <<EOF
Usage: $(basename "$0") PACKAGE

Build and install a package directory. Same version already installed is skipped.
Set FORCE=1 to reinstall.

Options:
  -h, --help  Show this help and exit
EOF

	return 0
}

# Build and install one package directory, skipping when the installed version matches.
#
# Inputs:
# - $1 package directory relative to repo root
#
# Side Effects:
# - may run makepkg -si in the package directory
# - reads FORCE to force reinstall of the same version
#
# Outputs:
# - skip message when the same version is already installed
#
# Returns:
# - 0 on success or skip
# - 1 when PKGBUILD is missing, version lookup fails, or makepkg fails
install_package() {
	local target="$1"
	local srcinfo
	local pkgname
	local epoch
	local pkgver
	local pkgrel
	local version
	local installed

	[[ -n "${target}" ]] || {
		echo "install_package:: target is required" >&2
		return 1
	}

	[[ -f "${target}/PKGBUILD" ]] || {
		echo "install_package:: no PKGBUILD in ${target}" >&2
		return 1
	}

	srcinfo="$(cd "${target}" && makepkg --printsrcinfo)" || return 1

	pkgname="$(awk '$1 == "pkgname" { print $3; exit }' <<<"${srcinfo}")"
	epoch="$(awk '$1 == "epoch" { print $3; exit }' <<<"${srcinfo}")"
	pkgver="$(awk '$1 == "pkgver" { print $3; exit }' <<<"${srcinfo}")"
	pkgrel="$(awk '$1 == "pkgrel" { print $3; exit }' <<<"${srcinfo}")"
	version="${epoch:+${epoch}:}${pkgver}-${pkgrel}"
	installed="$(pacman -Q "${pkgname}" 2>/dev/null | awk '{ print $2 }')" || true

	if [[ -z "${FORCE:-}" && "${installed}" == "${version}" ]]; then
		echo "install_package:: skipped ${target} (${pkgname} ${version} already installed)"

		return 0
	fi

	(cd "${target}" && makepkg -si) || return 1

	return 0
}

main() {
	local target

	case "${1:-}" in
	-h | --help)
		usage
		return 0
		;;
	"")
		echo "main:: package directory is required" >&2
		return 1
		;;
	-*)
		echo "main:: unknown option '$1'" >&2
		return 1
		;;
	*)
		target="${1%/}"
		;;
	esac

	cd "${ROOT}" || return 1
	install_package "${target}" || return 1

	return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -eo pipefail
	umask 077
	main "$@"
	exit $?
fi

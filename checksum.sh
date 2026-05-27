#!/usr/bin/env bash
#
# Validate sha512 checksums for binary repack packages against upstream sources.
#

GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"

usage() {
	cat <<EOF
Usage: $(basename "$0") [OPTION]...

Verify sha512sums in a package PKGBUILD against upstream sources.

Options:
  -h, --help            Show this help and exit
  -t, --target TARGET   Package directory to verify, repeatable

EOF
}

main() {
	local targets=()
	local target
	local failures=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			usage
			return 0
			;;
		-t | --target)
			shift
			if [[ -z "${1:-}" ]]; then
				echo "main:: --target requires a package directory" >&2
				return 1
			fi
			targets+=("${1%/}")
			;;
		*)
			echo "main:: unknown option '$1'" >&2
			return 1
			;;
		esac
		shift
	done

	if [[ -z "$GIT_ROOT" ]]; then
		echo "main:: could not resolve git repository root" >&2
		return 1
	fi

	if [[ "${#targets[@]}" -eq 0 ]]; then
		echo "main:: at least one --target is required" >&2
		return 1
	fi

	cd "$GIT_ROOT" || return 1

	for target in "${targets[@]}"; do
		if [[ ! -f "${target}/PKGBUILD" ]]; then
			echo "main:: no PKGBUILD in ${target}" >&2
			failures=$((failures + 1))
			continue
		fi

		echo "checksum:: verifying ${target}"
		if ! (cd "${target}" && makepkg -f --verifysource --nocolor); then
			echo "main:: checksum verification failed for ${target}" >&2
			failures=$((failures + 1))
			continue
		fi

		echo "checksum:: ${target} passed"
	done

	if [[ "${failures}" -gt 0 ]]; then
		echo "main:: finished with ${failures} failure(s)" >&2
		return 1
	fi

	echo "checksum:: all packages passed"
	return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -eo pipefail
	umask 077
	main "$@"
	exit $?
fi

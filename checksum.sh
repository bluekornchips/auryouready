#!/usr/bin/env bash
#
# Verify or update sha512 checksums for package PKGBUILDs against upstream sources.
#

GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"

usage() {
	cat <<EOF
Usage: $(basename "$0") [OPTION]...

Verify or update sha512sums in a package PKGBUILD against upstream sources.

Options:
  -h, --help            Show this help and exit
  -t, --target TARGET   Package directory to process, repeatable
  -u, --update          Download sources and rewrite sha512sums in PKGBUILD

EOF
}

# Run a checksum step for one package directory
#
# Inputs:
# - $1 package directory relative to repo root
# - $2 progress verb, e.g. updating or verifying
# - $3 success word, e.g. updated or passed
# - remaining args: command and flags to run inside the package dir
#
# Side Effects:
# - Runs the given command in a cd subshell under the package dir
# - Writes progress and errors to stdout/stderr
#
# Returns:
# - 0 on success
# - 1 on failure
_run_step() {
	local target="$1"
	local verb="$2"
	local done_word="$3"
	shift 3

	echo "checksum:: ${verb} ${target}"
	if ! (cd "${target}" && "$@"); then
		echo "_run_step:: ${verb} failed for ${target}" >&2
		return 1
	fi
	echo "checksum:: ${target} ${done_word}"

	return 0
}

# Rewrite sha512sums for one package directory via updpkgsums
#
# Inputs:
# - $1 package directory relative to repo root
#
# Side Effects:
# - Runs updpkgsums, rewriting sha512sums in PKGBUILD
# - Writes progress and errors to stdout/stderr
#
# Returns:
# - 0 on success
# - 1 on failure
_update() {
	_run_step "$1" updating updated updpkgsums --nocolor
}

# Verify sha512sums for one package directory via makepkg
#
# Inputs:
# - $1 package directory relative to repo root
#
# Side Effects:
# - Runs makepkg --verifysource
# - Writes progress and errors to stdout/stderr
#
# Returns:
# - 0 on success
# - 1 on failure
_verify() {
	_run_step "$1" verifying passed makepkg -f --verifysource --nocolor
}

# Process one package directory
#
# Inputs:
# - $1 package directory relative to repo root
# - $2 mode: verify or update
#
# Side Effects:
# - Dispatches to _verify or _update
# - Writes errors to stderr for unknown modes or missing PKGBUILD
#
# Returns:
# - 0 on success
# - 1 on failure
process_target() {
	local target="$1"
	local mode="$2"

	if [[ ! -f "${target}/PKGBUILD" ]]; then
		echo "process_target:: no PKGBUILD in ${target}" >&2
		return 1
	fi

	case "${mode}" in
	update)
		_update "${target}"
		;;
	verify)
		_verify "${target}"
		;;
	*)
		echo "process_target:: unknown mode '${mode}'" >&2
		return 1
		;;
	esac
}

main() {
	local targets=()
	local mode="verify"
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
		-u | --update)
			mode="update"
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

	if [[ "${mode}" == "update" ]] && ! command -v updpkgsums >/dev/null 2>&1; then
		echo "main:: updpkgsums is not installed; install pacman-contrib" >&2
		return 1
	fi

	cd "$GIT_ROOT" || return 1

	for target in "${targets[@]}"; do
		if ! process_target "${target}" "${mode}"; then
			failures=$((failures + 1))
			continue
		fi
	done

	if [[ "${failures}" -gt 0 ]]; then
		echo "main:: finished with ${failures} failure(s)" >&2
		return 1
	fi

	if [[ "${mode}" == "update" ]]; then
		echo "checksum:: all packages updated"
	else
		echo "checksum:: all packages passed"
	fi

	return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -eo pipefail
	umask 077
	main "$@"
	exit $?
fi

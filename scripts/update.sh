#!/usr/bin/env bash
#
# Fetch upstream versions, rewrite PKGBUILD fields, and pin sha256sums.
#

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REQUIRED_COMMANDS=("curl" "updpkgsums")
PACKAGES_DIR="${ROOT}/scripts/packages"

# Print usage to stdout.
#
# Outputs:
# - usage text
#
# Returns:
# - 0 always
usage() {
	cat <<EOF
Usage: $(basename "$0") [-p PACKAGE]...

Fetch upstream versions for package directories, rewrite pkgver when newer,
reset pkgrel to 1, and run updpkgsums. Same version already latest is skipped.
With no -p flags, every package under scripts/packages is updated.

Options:
  -h, --help             Show this help and exit
  -p, --package PACKAGE  Package directory to update, repeatable
EOF

	return 0
}

# Check for required external commands.
#
# Side Effects:
# - Writes missing dependency messages to stderr
#
# Returns:
# - 0 when all commands exist
# - 1 when any command is missing
check_dependencies() {
	local missing=()

	local cmd
	for cmd in "${REQUIRED_COMMANDS[@]}"; do
		if ! command -v "${cmd}" >/dev/null 2>&1; then
			missing+=("${cmd}")
		fi
	done

	if [[ "${#missing[@]}" -gt 0 ]]; then
		echo "check_dependencies:: missing dependencies: ${missing[*]}" >&2
		return 1
	fi

	return 0
}

# Read one assignment value from a PKGBUILD.
#
# Inputs:
# - $1 PKGBUILD path
# - $2 field name without trailing equals, e.g. pkgver
#
# Outputs:
# - field value on stdout
#
# Returns:
# - 0 when the field is present and non-empty
# - 1 when the field is missing
read_pkgbuild_field() {
	local pkgbuild="$1"
	local field="$2"

	local value
	value="$(awk -F= -v key="${field}" '$1 == key { print $2; exit }' "${pkgbuild}")"

	[[ -n "${value}" ]] || {
		echo "read_pkgbuild_field:: ${field} missing in ${pkgbuild}" >&2
		return 1
	}

	printf '%s\n' "${value}"

	return 0
}

# Rewrite one assignment line in a PKGBUILD.
#
# Inputs:
# - $1 PKGBUILD path
# - $2 field name without trailing equals
# - $3 new value
#
# Side Effects:
# - Rewrites the matching line in the PKGBUILD
#
# Returns:
# - 0 on success
# - 1 when sed fails
set_pkgbuild_field() {
	local pkgbuild="$1"
	local field="$2"
	local value="$3"

	sed -i "s/^${field}=.*/${field}=${value}/" "${pkgbuild}" || {
		echo "set_pkgbuild_field:: failed to set ${field} in ${pkgbuild}" >&2
		return 1
	}

	return 0
}

# Fetch upstream metadata and update one package directory when newer.
#
# Inputs:
# - $1 package directory relative to repo root
#
# Side Effects:
# - Rewrites PKGBUILD fields and runs updpkgsums when upstream is newer
#
# Outputs:
# - skip or update messages on stdout
#
# Returns:
# - 0 on success or skip
# - 1 when PKGBUILD is missing, fetch fails, or update fails
update_package() {
	local target="$1"
	local pkgbuild="${target}/PKGBUILD"
	local fetcher="${PACKAGES_DIR}/${target}"

	[[ -n "${target}" ]] || {
		echo "update_package:: target is required" >&2
		return 1
	}

	[[ -f "${pkgbuild}" ]] || {
		echo "update_package:: no PKGBUILD in ${target}" >&2
		return 1
	}

	[[ -f "${fetcher}" ]] || {
		echo "update_package:: missing package fetcher ${fetcher}" >&2
		return 1
	}

	source "${fetcher}" || {
		echo "update_package:: failed to source ${fetcher}" >&2
		return 1
	}

	local local_pkgver
	local_pkgver="$(read_pkgbuild_field "${pkgbuild}" pkgver)" || return 1

	local upstream
	upstream="$(fetch_upstream)" || return 1

	local new_pkgver="${upstream%% *}"
	local new_commit=""
	if [[ "${upstream}" == *" "* ]]; then
		new_commit="${upstream#* }"
	fi

	local local_commit=""
	if [[ -n "${new_commit}" ]]; then
		local_commit="$(read_pkgbuild_field "${pkgbuild}" _commit)" || return 1
	fi

	if [[ "${local_pkgver}" == "${new_pkgver}" && "${local_commit}" == "${new_commit}" ]]; then
		echo "update_package:: skipped ${target} (${local_pkgver} already latest)"
		return 0
	fi

	echo "update_package:: ${target} ${local_pkgver} -> ${new_pkgver}"
	set_pkgbuild_field "${pkgbuild}" pkgver "${new_pkgver}" || return 1
	set_pkgbuild_field "${pkgbuild}" pkgrel 1 || return 1

	if [[ -n "${new_commit}" ]]; then
		set_pkgbuild_field "${pkgbuild}" _commit "${new_commit}" || return 1
	fi

	echo "update_package:: pinning ${target} (${new_pkgver})"
	(cd "${target}" && updpkgsums --nocolor) || {
		echo "update_package:: updpkgsums failed for ${target}" >&2
		return 1
	}

	return 0
}

main() {
	local targets=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			usage
			return 0
			;;
		-p | --package)
			shift
			[[ -n "${1:-}" ]] || {
				echo "main:: --package requires a package directory" >&2
				return 1
			}
			targets+=("${1%/}")
			;;
		-*)
			echo "main:: unknown option '$1'" >&2
			return 1
			;;
		*)
			echo "main:: unexpected argument '$1'" >&2
			return 1
			;;
		esac
		shift
	done

	if [[ "${#targets[@]}" -eq 0 ]]; then
		local fetcher
		for fetcher in "${PACKAGES_DIR}"/*; do
			[[ -f "${fetcher}" ]] || continue
			targets+=("$(basename "${fetcher}")")
		done
	fi

	[[ "${#targets[@]}" -gt 0 ]] || {
		echo "main:: no packages found under ${PACKAGES_DIR}" >&2
		return 1
	}

	check_dependencies || return 1
	cd "${ROOT}" || return 1

	local target
	for target in "${targets[@]}"; do
		update_package "${target}" || return 1
	done

	return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -eo pipefail
	umask 077
	main "$@"
	exit $?
fi

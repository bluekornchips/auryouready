#!/usr/bin/env bash
#
# Remove makepkg build outputs and downloaded .deb sources in each top-level PKGBUILD directory.
#

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  umask 077
fi

# Show usage for direct invocation.
#
# Side Effects:
# - Writes the help text to stdout
#
# Returns:
# - 0 always
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]

Remove pkg and src trees, built package archives, detached signatures, makepkg
logs, and downloaded .deb source files in each immediate subdirectory of the repository
root that holds a PKGBUILD.

Options:
  -h, --help  Show this help and exit

EOF
}

# Print the absolute path to the directory that contains this script.
#
# Outputs:
# - Writes one line, the repository root used for cleanup, to stdout
#
# Returns:
# - 0 on success
# - 1 if the path cannot be resolved
repo_root() {
  local root
  if ! root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; then
    echo "repo_root:: could not resolve script directory" >&2

    return 1
  fi

  printf '%s\n' "${root}"

  return 0
}

# Confirm rm is available before deleting anything.
#
# Returns:
# - 0 when rm is found
# - 1 when rm is missing from PATH
ensure_rm() {
  if ! command -v rm >/dev/null 2>&1; then
    echo "ensure_rm:: rm is not available in PATH" >&2

    return 1
  fi

  return 0
}

# Delete makepkg outputs under one package directory.
#
# Inputs:
# - $1: directory name relative to repo root, with or without a trailing slash
#
# Side Effects:
# - Removes pkg, src, package tarballs, detached signatures, matching logs, and .deb sources
#
# Outputs:
# - Progress lines to stdout when a PKGBUILD is present
#
# Returns:
# - 0 on success or when the directory has no PKGBUILD
# - 1 when the name is empty, or the path is not a directory
clean_package_dir() {
  local name
  local dir
  name="${1%/}"
  if [[ -z "${name}" ]]; then
    echo "clean_package_dir:: package directory name is required" >&2

    return 1
  fi

  dir="${name}/"
  if [[ ! -d "${dir}" ]]; then
    echo "clean_package_dir:: not a directory: ${dir}" >&2

    return 1
  fi

  if [[ ! -f "${dir}PKGBUILD" ]]; then
    return 0
  fi

  echo "cleanup:: cleaning ${name}"

  if [[ -e "${dir}pkg" ]] || [[ -L "${dir}pkg" ]]; then
    if ! rm -rf "${dir}pkg"; then
      echo "clean_package_dir:: failed to remove ${dir}pkg" >&2

      return 1
    fi
  fi

  if [[ -e "${dir}src" ]] || [[ -L "${dir}src" ]]; then
    if ! rm -rf "${dir}src"; then
      echo "clean_package_dir:: failed to remove ${dir}src" >&2

      return 1
    fi
  fi

  local artifacts
  artifacts=(
    "${dir}"*.pkg.tar.*
    "${dir}"*.pkg.tar.*.sig
    "${dir}"makepkg-*.log
    "${dir}"*.deb
  )
  if [[ ${#artifacts[@]} -gt 0 ]]; then
    if ! rm -f "${artifacts[@]}"; then
      echo "clean_package_dir:: failed to remove artifacts under ${dir}" >&2

      return 1
    fi
  fi

  return 0
}

main() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h | --help)
        usage

        return 0
        ;;
      *)
        echo "cleanup:: unknown option '$1'" >&2
        echo "cleanup:: use $(basename "$0") --help for usage" >&2

        return 1
        ;;
    esac
  done

  local root
  root="$(repo_root)" || return 1
  cd "${root}" || {
    echo "cleanup:: could not cd to ${root}" >&2

    return 1
  }

  ensure_rm || return 1

  shopt -s nullglob
  local d
  for d in */; do
    if ! clean_package_dir "${d}"; then
      return 1
    fi
  done

  echo "cleanup:: clean finished"

  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
  exit $?
fi

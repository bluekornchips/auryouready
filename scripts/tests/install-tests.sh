#!/usr/bin/env bats
# shellcheck shell=bash
#
# Tests for install.sh
#

GIT_ROOT="$(git rev-parse --show-toplevel || echo "")"
SCRIPT="${GIT_ROOT}/scripts/install.sh"
[[ -f "${SCRIPT}" ]] || {
	echo "setup:: Script not found: ${SCRIPT}" >&2
	return 1
}

setup() {
	# shellcheck source=../install.sh
	source "${SCRIPT}"

	MOCK_BIN="${BATS_TEST_TMPDIR}/mock-bin"
	mkdir -p "${MOCK_BIN}"
	PATH="${MOCK_BIN}:${PATH}"
	export PATH

	CALL_LOG="${BATS_TEST_TMPDIR}/calls.log"
	: >"${CALL_LOG}"
	export CALL_LOG

	PKG_DIR="${BATS_TEST_TMPDIR}/pkg"
	mkdir -p "${PKG_DIR}"
	: >"${PKG_DIR}/PKGBUILD"
	export PKG_DIR

	unset FORCE

	cat >"${MOCK_BIN}/makepkg" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "--printsrcinfo" ]]; then
	cat <<INFO
pkgname = test-package
pkgver = 1.0
pkgrel = 1
INFO
else
	printf 'makepkg %s\n' "$*" >>"${CALL_LOG}"
fi
EOF
	chmod +x "${MOCK_BIN}/makepkg"

	return 0
}

install_pacman_mock() {
	local version="$1"

	cat >"${MOCK_BIN}/pacman" <<EOF
#!/usr/bin/env bash
printf 'test-package ${version}\\n'
EOF
	chmod +x "${MOCK_BIN}/pacman"

	return 0
}

@test "main:: --help prints usage and exits 0" {
	run bash "${SCRIPT}" --help
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "Usage:"
}

@test "main:: requires package directory" {
	run main
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "main:: package directory is required"
}

@test "main:: rejects unknown option" {
	run main --nope
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "main:: unknown option"
}

@test "install_package:: auto-skips same version" {
	install_pacman_mock "1.0-1"

	run install_package "${PKG_DIR}"
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "already installed"
	[[ ! -s "${CALL_LOG}" ]]
}

@test "install_package:: installs newer version" {
	install_pacman_mock "0.9-1"

	run install_package "${PKG_DIR}"
	[[ "${status}" -eq 0 ]]
	grep -qx "makepkg -si" "${CALL_LOG}"
}

@test "install_package:: FORCE reinstalls same version" {
	install_pacman_mock "1.0-1"
	FORCE=1
	export FORCE

	run install_package "${PKG_DIR}"
	[[ "${status}" -eq 0 ]]
	grep -qx "makepkg -si" "${CALL_LOG}"
}

@test "install_package:: fails when PKGBUILD is missing" {
	run install_package "${BATS_TEST_TMPDIR}/missing"
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "no PKGBUILD"
}

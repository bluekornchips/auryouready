#!/usr/bin/env bats
# shellcheck shell=bash
#
# Tests for install.sh
#

setup_file() {
	GIT_ROOT="$(git rev-parse --show-toplevel || echo "")"
	if [[ -z "${GIT_ROOT}" ]]; then
		fail "Failed to get git root"
	fi

	SCRIPT="${GIT_ROOT}/install.sh"
	if [[ ! -f "${SCRIPT}" ]]; then
		fail "Script not found: ${SCRIPT}"
	fi

	export GIT_ROOT
	export SCRIPT

	return 0
}

setup() {
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
	echo "${output}" | grep -q -- "-t, --target"
}

@test "install_target:: skips same version when declined" {
	install_pacman_mock "1.0-1"

	run bash -c 'source "$1"; printf "n\n" | install_target "$2"' _ \
		"${SCRIPT}" "${PKG_DIR}"
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "install skipped"
	[[ ! -s "${CALL_LOG}" ]]
}

@test "install_target:: installs same version when confirmed" {
	install_pacman_mock "1.0-1"

	run bash -c 'source "$1"; printf "y\n" | install_target "$2"' _ \
		"${SCRIPT}" "${PKG_DIR}"
	[[ "${status}" -eq 0 ]]
	grep -qx "makepkg -si" "${CALL_LOG}"
}

@test "install_target:: installs newer version without prompt" {
	install_pacman_mock "0.9-1"

	run bash -c 'source "$1"; install_target "$2"' _ \
		"${SCRIPT}" "${PKG_DIR}"
	[[ "${status}" -eq 0 ]]
	grep -qx "makepkg -si" "${CALL_LOG}"
}

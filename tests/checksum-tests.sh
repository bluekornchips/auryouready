#!/usr/bin/env bats
#
# Tests for checksum.sh
#

setup_file() {
	GIT_ROOT="$(git rev-parse --show-toplevel || echo "")"
	if [[ -z "${GIT_ROOT}" ]]; then
		fail "Failed to get git root"
	fi

	SCRIPT="${GIT_ROOT}/checksum.sh"
	if [[ ! -f "${SCRIPT}" ]]; then
		fail "Script not found: ${SCRIPT}"
	fi

	export GIT_ROOT
	export SCRIPT

	return 0
}

setup() {
	# shellcheck source=../checksum.sh
	source "${SCRIPT}"

	MOCK_BIN="${BATS_TEST_TMPDIR}/mock-bin"
	mkdir -p "${MOCK_BIN}"
	PATH="${MOCK_BIN}:${PATH}"
	export PATH
	export MOCK_BIN

	CALL_LOG="${BATS_TEST_TMPDIR}/calls.log"
	: >"${CALL_LOG}"
	export CALL_LOG

	PKG_DIR="${BATS_TEST_TMPDIR}/pkg"
	mkdir -p "${PKG_DIR}"
	: >"${PKG_DIR}/PKGBUILD"
	export PKG_DIR

	return 0
}

# Write a mock command that logs args and exits with the given status
#
# Inputs:
# - $1 command name
# - $2 exit status
install_mock() {
	local name="$1"
	local status="$2"

	cat >"${MOCK_BIN}/${name}" <<EOF
#!/usr/bin/env bash
printf '%s' '${name}' >>"${CALL_LOG}"
if [[ \$# -gt 0 ]]; then
	printf ' %s' "\$@" >>"${CALL_LOG}"
fi
printf '\\n' >>"${CALL_LOG}"
exit ${status}
EOF
	chmod +x "${MOCK_BIN}/${name}"

	return 0
}

@test "_update:: succeeds when updpkgsums succeeds" {
	install_mock updpkgsums 0

	run _update "${PKG_DIR}"
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "checksum:: updating ${PKG_DIR}"
	echo "${output}" | grep -q "checksum:: ${PKG_DIR} updated"
	grep -qx "updpkgsums --nocolor" "${CALL_LOG}"
}

@test "_update:: fails when updpkgsums fails" {
	install_mock updpkgsums 1

	run _update "${PKG_DIR}"
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "_run_step:: updating failed for ${PKG_DIR}"
}

@test "_verify:: succeeds when makepkg succeeds" {
	install_mock makepkg 0

	run _verify "${PKG_DIR}"
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "checksum:: verifying ${PKG_DIR}"
	echo "${output}" | grep -q "checksum:: ${PKG_DIR} passed"
	grep -qx "makepkg -f --verifysource --nocolor" "${CALL_LOG}"
}

@test "_verify:: fails when makepkg fails" {
	install_mock makepkg 1

	run _verify "${PKG_DIR}"
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "_run_step:: verifying failed for ${PKG_DIR}"
}

@test "process_target:: fails when PKGBUILD is missing" {
	run process_target "${BATS_TEST_TMPDIR}/missing" verify
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "process_target:: no PKGBUILD"
}

@test "process_target:: routes update mode to _update" {
	install_mock updpkgsums 0

	run process_target "${PKG_DIR}" update
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "checksum:: updating ${PKG_DIR}"
}

@test "process_target:: routes verify mode to _verify" {
	install_mock makepkg 0

	run process_target "${PKG_DIR}" verify
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "checksum:: verifying ${PKG_DIR}"
}

@test "process_target:: rejects unknown mode" {
	run process_target "${PKG_DIR}" nope
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "process_target:: unknown mode"
}

@test "main:: requires at least one --target" {
	run main
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "main:: at least one --target is required"
}

@test "main:: --help prints usage and exits 0" {
	run main --help
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "Usage:"
	echo "${output}" | grep -q -- "-u, --update"
}

@test "main:: rejects unknown option" {
	run main --nope
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "main:: unknown option"
}

@test "main:: --target without value fails" {
	run main --target
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "main:: --target requires a package directory"
}

@test "main:: --update fails when updpkgsums is missing" {
	local empty_path
	local saved_path="${PATH}"
	empty_path="${BATS_TEST_TMPDIR}/empty-path"
	mkdir -p "${empty_path}"

	PATH="${empty_path}"
	export PATH

	run main --update -t cursor

	PATH="${saved_path}"
	export PATH

	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"main:: updpkgsums is not installed"* ]]
}

@test "main:: verify happy path reports all packages passed" {
	install_mock makepkg 0

	GIT_ROOT="${BATS_TEST_TMPDIR}/fake-root"
	mkdir -p "${GIT_ROOT}/pkg"
	: >"${GIT_ROOT}/pkg/PKGBUILD"

	run main -t pkg
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "checksum:: all packages passed"
}

@test "main:: update happy path reports all packages updated" {
	install_mock updpkgsums 0

	GIT_ROOT="${BATS_TEST_TMPDIR}/fake-root"
	mkdir -p "${GIT_ROOT}/pkg"
	: >"${GIT_ROOT}/pkg/PKGBUILD"

	run main --update -t pkg
	[[ "${status}" -eq 0 ]]
	echo "${output}" | grep -q "checksum:: all packages updated"
}

@test "main:: aggregates multiple target failures" {
	install_mock makepkg 1

	GIT_ROOT="${BATS_TEST_TMPDIR}/fake-root"
	mkdir -p "${GIT_ROOT}/pkg-a" "${GIT_ROOT}/pkg-b"
	: >"${GIT_ROOT}/pkg-a/PKGBUILD"
	: >"${GIT_ROOT}/pkg-b/PKGBUILD"

	run main -t pkg-a -t pkg-b
	[[ "${status}" -eq 1 ]]
	echo "${output}" | grep -q "main:: finished with 2 failure(s)"
}

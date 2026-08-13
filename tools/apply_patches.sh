#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && git rev-parse --show-toplevel)"
PATCHES_QUEUE_DIR="${REPO_ROOT}/patches_queue"
SCRCPY_DIR="${REPO_ROOT}/scrcpy"

echo "Repository root: ${REPO_ROOT}"
echo "Patches queue:   ${PATCHES_QUEUE_DIR}"
echo "Scrcpy submodule: ${SCRCPY_DIR}"

if [ ! -d "${PATCHES_QUEUE_DIR}" ]; then
    echo "Error: patches_queue directory not found: ${PATCHES_QUEUE_DIR}"
    exit 1
fi

if [ ! -d "${SCRCPY_DIR}" ]; then
    echo "Error: scrcpy submodule directory not found: ${SCRCPY_DIR}"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required but was not found in PATH"
    exit 1
fi

if ! git -C "${SCRCPY_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: scrcpy is not a valid git repository. Have you initialized submodules?"
    echo "Run: git submodule update --init --recursive"
    exit 1
fi

echo
echo "=== Resetting scrcpy submodule to a clean state ==="
git -C "${SCRCPY_DIR}" reset --hard --quiet
git -C "${SCRCPY_DIR}" clean -fd --quiet

echo
echo "=== Applying patches ==="
FAILED=0
TOTAL=0
APPLIED=0

apply_one() {
    local patch_path="$1"
    local patch_name
    patch_name="$(basename "${patch_path}")"
    TOTAL=$((TOTAL + 1))
    if git -C "${SCRCPY_DIR}" apply --recount -- "${patch_path}"; then
        APPLIED=$((APPLIED + 1))
        echo "  [ OK ] ${patch_name}"
    else
        FAILED=1
        echo "  [FAIL] ${patch_name}"
        echo "         -> git apply exited with code $? for ${patch_path}"
    fi
}

GRADLEW_PATCH="${PATCHES_QUEUE_DIR}/gradlew.patch"
if [ -f "${GRADLEW_PATCH}" ]; then
    echo "Root patches:"
    apply_one "${GRADLEW_PATCH}"
fi

if [ -d "${PATCHES_QUEUE_DIR}/server" ]; then
    echo
    echo "Server patches:"
    while IFS= read -r -d '' patch_path; do
        apply_one "${patch_path}"
    done < <(find "${PATCHES_QUEUE_DIR}/server" -name "*.patch" -print0 | sort -z)
fi

if [ -d "${PATCHES_QUEUE_DIR}/client" ]; then
    echo
    echo "Client patches:"
    while IFS= read -r -d '' patch_path; do
        apply_one "${patch_path}"
    done < <(find "${PATCHES_QUEUE_DIR}/client" -name "*.patch" -print0 | sort -z)
fi

echo
if [ "${FAILED}" -eq 0 ]; then
    echo "All ${APPLIED} patch(es) applied successfully."
    exit 0
else
    echo "Done: ${APPLIED}/${TOTAL} applied, some failed."
    exit 1
fi

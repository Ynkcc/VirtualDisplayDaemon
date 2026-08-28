#!/usr/bin/env bash

#
# Usage:
#   tools/update_patches.sh
#
# Output layout mirrors what apply_patches.sh applies:
#   patches_queue/gradlew.patch                      (applies at scrcpy root)
#   patches_queue/server/<rel-path>.patch            (applies at scrcpy root)

set -euo pipefail

# Load canonical paths + submodule checks.
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_SCRIPT_DIR}/lib/common.sh"

BASE="origin/master"
TARGET="origin/daemon-mode"

ensure_scrcpy_submodule

cd "${SCRCPY_DIR}"

# Fail fast if the reference branches are missing or the submodule is stale.
for ref in "${BASE}" "${TARGET}"; do
    if ! git rev-parse --verify --quiet "${ref}" >/dev/null; then
        echo "[ERROR] missing ref ${ref} in scrcpy submodule." >&2
        echo "        Hint: run 'git -C ${SCRCPY_DIR} fetch origin'" >&2
        exit 1
    fi
done

echo "Scrcpy submodule : ${SCRCPY_DIR}"
echo "Patches queue    : ${PATCHES_QUEUE_DIR}"
echo "Diffing          : ${BASE}..${TARGET}"

# Rebuild the queue from scratch so stale patches never linger.
rm -rf "${PATCHES_QUEUE_DIR}"
mkdir -p "${PATCHES_QUEUE_DIR}/server"

CHANGED_FILES="$(git diff --name-only "${BASE}" "${TARGET}")"
if [ -z "${CHANGED_FILES}" ]; then
    echo "No changes between ${BASE} and ${TARGET}; nothing to generate."
    exit 0
fi

PATCH_COUNT=0

# Emit a patch for every changed file, keyed by its path relative to scrcpy root.
while IFS= read -r file; do
    [ -z "${file}" ] && continue

    if [ "${file}" = "gradlew" ]; then
        out="${PATCHES_QUEUE_DIR}/gradlew.patch"
        mkdir -p "$(dirname "${out}")"
        git diff "${BASE}" "${TARGET}" -- "${file}" > "${out}"
    else
        rel="${file#server/}"                    # drop the 'server/' prefix
        out="${PATCHES_QUEUE_DIR}/server/${rel}.patch"
        mkdir -p "$(dirname "${out}")"
        git diff "${BASE}" "${TARGET}" -- "${file}" > "${out}"
    fi

    PATCH_COUNT=$((PATCH_COUNT + 1))
    echo "  + ${out}"
done <<< "${CHANGED_FILES}"

echo "------------------------------------------------"
echo "Generated ${PATCH_COUNT} patch file(s)."
echo "Done."

#!/usr/bin/env bash
#
# Apply the daemon-mode patches from patches_queue/ onto the scrcpy submodule.
#
# The scrcpy submodule stays on a clean 'master' checkout. All daemon-mode
# work (added under server/src/main/java/com/genymobile/scrcpy/daemon, plus
# modifications to a few upstream files) is shipped as individual patches in
# patches_queue/. This script is the single entry point that materialises
# those patches so the Android app can compile the daemon sources directly.
#
# Usage:
#   tools/apply_patches.sh              # apply idempotently (skip if already applied)
#   tools/apply_patches.sh --force      # restore baselines, re-apply from scratch
#   tools/apply_patches.sh -f           # shorthand for --force
#
# Exit codes:
#   0  success (or nothing to do / already applied)
#   1  failure (missing prerequisites, conflicting local state, apply error)

set -euo pipefail

# Load canonical paths + submodule checks.
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_SCRIPT_DIR}/lib/common.sh"

FORCE=false
if [ "${1:-}" = "--force" ] || [ "${1:-}" = "-f" ]; then
    FORCE=true
fi

# Server file that carries local, non-patch edits on master. git apply needs a
# clean baseline for it, otherwise the patch context will not match.
BUILD_GRADLE_REL="server/build.gradle"

# Marker that the daemon sources have been applied.
DAEMON_DIR_REL="server/src/main/java/com/genymobile/scrcpy/daemon"
DAEMON_DIR_ABS="${SCRCPY_DIR}/${DAEMON_DIR_REL}"

ensure_scrcpy_submodule
require_patches_queue

cd "${SCRCPY_DIR}"

# ---------------------------------------------------------------------------
# Baseline & idempotency
# ---------------------------------------------------------------------------
is_applied() {
    [ -d "${DAEMON_DIR_ABS}" ]
}

if is_applied && [ "${FORCE}" = false ]; then
    echo "[apply_patches] daemon sources already applied (${DAEMON_DIR_REL}); nothing to do."
    echo "                Re-run with --force to restore baselines and re-apply."
    exit 0
fi

if [ "${FORCE}" = true ]; then
    echo "[apply_patches] --force: restoring scrcpy baselines before re-applying..."

    # Restore the files that the patches modify in place to their pristine
    # master state, then drop untracked files introduced by the patches.
    # `git checkout -- gradlew server/` reverts the gradlew wrapper and the
    # whole server/ tree (all patch-modified files), so every git apply below
    # sees a clean baseline. Never run git clean -fd on the whole repo: that
    # would also drop unrelated untracked files. `git clean` without -x keeps
    # gitignored files intact (e.g. server/build Gradle outputs).
    git checkout -- gradlew server/ 2>/dev/null || true
    git clean -fd -- server/ || true
fi

# Restore the server build file to its pristine master state before applying.
# This is a hard prerequisite: git apply cannot match the patch context
# against the locally edited version of server/build.gradle. Only this file is
# touched; the config/android-checkstyle.gradle local edit is left untouched.
if ! git diff --quiet -- "${BUILD_GRADLE_REL}"; then
    echo "[apply_patches] Restoring ${BUILD_GRADLE_REL} to pristine master baseline (required by the patch context)..."
    git checkout -- "${BUILD_GRADLE_REL}"
fi

# ---------------------------------------------------------------------------
# Apply patches
# ---------------------------------------------------------------------------
echo "[apply_patches] Applying gradlew.patch (at scrcpy root)..."
if [ -f "${PATCHES_QUEUE_DIR}/gradlew.patch" ]; then
    # Idempotency: gradlew.patch injects a Java-21 auto-detection block. If the
    # marker is already present the patch has been applied; applying again would
    # fail because the context no longer matches.
    if grep -q 'JAVA_21_HOME="/usr/lib/jvm/java-21-openjdk"' gradlew; then
        echo "[apply_patches] gradlew.patch already applied; skipping."
    else
        git apply --recount --verbose "${PATCHES_QUEUE_DIR}/gradlew.patch"
    fi
else
    echo "[apply_patches] ${PATCHES_QUEUE_DIR}/gradlew.patch not found; skipping."
fi

echo "[apply_patches] Applying server patches (${PATCHES_QUEUE_DIR}/server)..."
SERVER_PATCH_COUNT=0
SKIPPED_PATCH_COUNT=0
while IFS= read -r patch_path; do
    # A patch is "new-file" when its diff header shows it is created from
    # /dev/null (--- /dev/null). Such a file is only applied once: if it already
    # exists the patch was already applied, so skip it to stay idempotent on
    # partial re-runs. Modified-file patches must always be applied — their
    # baseline was restored above, so the context will match.
    if grep -q '^--- /dev/null' "${patch_path}"; then
        target_rel="$(sed -n 's/^+++ b\/\(.*\)$/\1/p' "${patch_path}" | head -1)"
        if [ -n "${target_rel}" ] && [ -f "${SCRCPY_DIR}/${target_rel}" ]; then
            echo "  ~ $(basename "${patch_path}") (new-file already present; skipping)"
            SKIPPED_PATCH_COUNT=$((SKIPPED_PATCH_COUNT + 1))
            continue
        fi
    fi
    echo "  + $(basename "${patch_path}")"
    git apply --recount --verbose "${patch_path}"
    SERVER_PATCH_COUNT=$((SERVER_PATCH_COUNT + 1))
done < <(find "${PATCHES_QUEUE_DIR}/server" -name "*.patch" | sort)

# Make sure the gradlew wrapper stays executable (gradlew.patch may touch it).
chmod +x ./gradlew

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------
if ! is_applied; then
    echo "[apply_patches] ERROR: daemon sources were not produced at ${DAEMON_DIR_REL}." >&2
    exit 1
fi

echo "[apply_patches] Done. Applied ${SERVER_PATCH_COUNT} server patch(es) (${SKIPPED_PATCH_COUNT} already present)."
echo "                Daemon sources ready under ${DAEMON_DIR_REL}."

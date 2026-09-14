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
# Per-patch idempotency: every patch is classified on its own (APPLIED / CLEAN /
# CONFLICT) before being applied, so a single missing or half-applied file is
# repaired by a plain re-run — without needing --force, which discards every
# local change in the submodule.
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

# Per-patch counters (populated by apply_one_patch).
APPLIED_PATCH_COUNT=0
SKIPPED_PATCH_COUNT=0
CONFLICT_PATCH_COUNT=0

# Classify and apply a single patch.
#
#   APPLIED  → the patch is already in the tree (its reverse applies cleanly)
#   CLEAN    → the patch applies cleanly onto the current tree
#   CONFLICT → neither direction applies: the tree drifted from both the
#              baseline and the patched state, so applying it would either fail
#              or silently produce a half-patched file. Report and let the
#              caller decide (the caller turns this into a hard error).
apply_one_patch() {
    local patch_path="$1"
    local rel="${patch_path#"${PATCHES_QUEUE_DIR}/"}"
    if git apply --check --reverse "${patch_path}" >/dev/null 2>&1; then
        echo "  ~ ${rel} (already applied; skipping)"
        SKIPPED_PATCH_COUNT=$((SKIPPED_PATCH_COUNT + 1))
    elif git apply --check "${patch_path}" >/dev/null 2>&1; then
        echo "  + ${rel}"
        git apply --recount --verbose "${patch_path}"
        APPLIED_PATCH_COUNT=$((APPLIED_PATCH_COUNT + 1))
    else
        echo "  ! ${rel} (drifted: neither applies nor reverses cleanly)" >&2
        CONFLICT_PATCH_COUNT=$((CONFLICT_PATCH_COUNT + 1))
    fi
}

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
    apply_one_patch "${PATCHES_QUEUE_DIR}/gradlew.patch"
else
    echo "[apply_patches] ${PATCHES_QUEUE_DIR}/gradlew.patch not found; skipping."
fi

echo "[apply_patches] Applying server patches (${PATCHES_QUEUE_DIR}/server)..."
while IFS= read -r patch_path; do
    apply_one_patch "${patch_path}"
done < <(find "${PATCHES_QUEUE_DIR}/server" -name "*.patch" | sort)

# Make sure the gradlew wrapper stays executable (gradlew.patch may touch it).
chmod +x ./gradlew

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------
if [ "${CONFLICT_PATCH_COUNT}" -gt 0 ]; then
    echo "[apply_patches] ERROR: ${CONFLICT_PATCH_COUNT} patch(es) conflict with the current scrcpy tree." >&2
    echo "                Re-run with --force to restore the pristine baseline and re-apply everything." >&2
    exit 1
fi

if ! is_applied; then
    echo "[apply_patches] ERROR: daemon sources were not produced at ${DAEMON_DIR_REL}." >&2
    exit 1
fi

echo "[apply_patches] Done. Applied ${APPLIED_PATCH_COUNT} patch(es), skipped ${SKIPPED_PATCH_COUNT} already applied."
echo "                Daemon sources ready under ${DAEMON_DIR_REL}."

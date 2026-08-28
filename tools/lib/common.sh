#!/usr/bin/env bash
#
# Common helpers shared by the daemon build/ops scripts.
#
# Sources this file to obtain the canonical repo paths and a one-shot
# scrcpy submodule check. Every tool script should `source` this instead of
# re-deriving the same paths, so the layout stays consistent across scripts.

set -euo pipefail

# ---------------------------------------------------------------------------
# Canonical path resolution
# ---------------------------------------------------------------------------
# Locate the enclosing daemon repo regardless of the current
# working directory. tools/lib/common.sh -> tools/ -> repo root.
_COMMON_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "${_COMMON_SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${TOOLS_DIR}/.." && pwd)"

SCRCPY_DIR="${REPO_ROOT}/scrcpy"
PATCHES_QUEUE_DIR="${REPO_ROOT}/patches_queue"

# ---------------------------------------------------------------------------
# scrcpy submodule sanity checks
# ---------------------------------------------------------------------------
# Verify the scrcpy submodule is present and is a git repository.
require_scrcpy() {
    if [ ! -d "${SCRCPY_DIR}" ]; then
        echo "[ERROR] scrcpy submodule not found: ${SCRCPY_DIR}" >&2
        echo "        Hint: run 'git -C ${REPO_ROOT} submodule update --init --recursive'" >&2
        return 1
    fi
    if ! git -C "${SCRCPY_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
        echo "[ERROR] '${SCRCPY_DIR}' is not a git repository." >&2
        echo "        Hint: run 'git -C ${REPO_ROOT} submodule update --init --recursive'" >&2
        return 1
    fi
}

# Make sure the local scrcpy submodule is initialized before operating on it.
ensure_scrcpy_submodule() {
    require_scrcpy || return 1
    git -C "${REPO_ROOT}" submodule update --init --recursive
}

# Require the patches queue directory to exist.
require_patches_queue() {
    if [ ! -d "${PATCHES_QUEUE_DIR}" ]; then
        echo "[ERROR] patches queue not found: ${PATCHES_QUEUE_DIR}" >&2
        return 1
    fi
}

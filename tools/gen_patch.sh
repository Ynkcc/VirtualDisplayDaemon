#!/bin/bash
#
# Generate a new-file patch for a single file under the scrcpy submodule.
#
# Usage:
#   tools/gen_patch.sh <path-relative-to-scrcpy-root>
#
# Example:
#   tools/gen_patch.sh server/src/main/java/com/genymobile/scrcpy/daemon/net/TcpServerSocketListener.java
#
# The script runs inside the scrcpy submodule and diffs the file against
# /dev/null, so the emitted patch header carries the canonical `server/...`
# path (no `scrcpy/` prefix) plus git's native `index` blob-hash line — exactly
# matching what `git diff` produces for the rest of patches_queue/.

set -euo pipefail

TARGET_FILE=$1

# Locate the scrcpy submodule root (this script lives at tools/gen_patch.sh,
# so the submodule is <repo-root>/scrcpy).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRCPY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/scrcpy"

cd "${SCRCPY_DIR}"

# `--no-index` is required because the daemon sources are untracked in the
# scrcpy submodule, and plain `git diff` does not emit untracked files. git
# exits 1 when the two paths differ (the expected case here), so tolerate it.
git diff --no-index -- /dev/null "${TARGET_FILE}" || true

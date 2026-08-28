#!/bin/bash
#
# Generate a patch for a single file under the scrcpy submodule, covering
# BOTH cases:
#   - a NEW file (untracked in scrcpy)      → diff against /dev/null
#   - a MODIFIED upstream file (tracked)    → git diff against HEAD
#
# Usage:
#   tools/gen_patch.sh <path-relative-to-scrcpy-root>
#
# Example:
#   tools/gen_patch.sh server/src/main/java/com/genymobile/scrcpy/daemon/net/TcpServerSocketListener.java
#   tools/gen_patch.sh server/src/main/java/com/genymobile/scrcpy/video/ScreenCapture.java
#
# The script runs inside the scrcpy submodule. It inspects whether the target
# file is tracked by git:
#   - untracked → emitted as a new-file patch (diff vs /dev/null), so the patch
#     header carries the canonical `server/...` path (no `scrcpy/` prefix) plus
#     git's native `index` blob-hash line — matching the rest of patches_queue/.
#   - tracked   → emitted as a MODIFY patch (git diff vs HEAD), matching what
#     apply.sh classifies as an upstream modification.
#
# Output goes to stdout; redirect to the matching path under patches_queue/.

set -euo pipefail

TARGET_FILE=${1:?usage: gen_patch.sh <path-relative-to-scrcpy-root>}

# Locate the scrcpy submodule root (this script lives at tools/gen_patch.sh,
# so the submodule is <repo-root>/scrcpy).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRCPY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)/scrcpy"

cd "${SCRCPY_DIR}"

if [ ! -f "${TARGET_FILE}" ]; then
    echo "错误: 目标文件不存在: ${TARGET_FILE}" >&2
    exit 1
fi

if git ls-files --error-unmatch -- "${TARGET_FILE}" >/dev/null 2>&1; then
    # Tracked → upstream file modification. Diff against HEAD.
    git diff -- "${TARGET_FILE}"
else
    # Untracked → new daemon source file. Diff against /dev/null.
    # `--no-index` is required because plain `git diff` does not emit untracked
    # files; git exits 1 when the two paths differ (the expected case here), so
    # tolerate it.
    git diff --no-index -- /dev/null "${TARGET_FILE}" || true
fi

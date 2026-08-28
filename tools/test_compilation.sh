#!/usr/bin/env bash
#
# Test that the daemon-mode patches compile against the scrcpy submodule.
#
# Workflow (meant for CI / local verification only — it DESTROYS the local
# scrcpy checkout state):
#   1. Reset the local scrcpy submodule to a pristine 'master'.
#   2. Apply patches from patches_queue/ via apply_patches.sh (single entry point).
#   3. Build the server module inside the submodule (./gradlew :server:assembleDebug).
#
# Usage:
#   tools/test_compilation.sh

set -euo pipefail

# Load canonical paths + submodule checks.
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${_SCRIPT_DIR}/lib/common.sh"

ensure_scrcpy_submodule
require_patches_queue

# ---------------------------------------------------------------------------
# 1. Restore a pristine master checkout inside the submodule
# ---------------------------------------------------------------------------
cd "${SCRCPY_DIR}"
echo "[test] Resetting local scrcpy checkout to pristine master..."
git reset --hard
git clean -fd

# Ensure local.properties exists for the Gradle build.
echo "sdk.dir=${ANDROID_HOME:-}" > local.properties

# ---------------------------------------------------------------------------
# 2. Apply the patches (delegated to the single entry point)
# ---------------------------------------------------------------------------
echo "[test] Applying patches..."
"${TOOLS_DIR}/apply_patches.sh" --force

# ---------------------------------------------------------------------------
# 3. Build the server component
# ---------------------------------------------------------------------------
echo "[test] Building scrcpy server..."
# Ensure gradlew is executable (it may have been patched).
chmod +x ./gradlew
./gradlew :server:assembleDebug

BUILD_RESULT=$?

if [ ${BUILD_RESULT} -eq 0 ]; then
    echo "------------------------------------------------"
    echo "[test] SUCCESS: the patches compile correctly on the scrcpy submodule."
    echo "------------------------------------------------"
else
    echo "------------------------------------------------"
    echo "[test] FAILURE: compilation failed."
    echo "------------------------------------------------"
fi

exit ${BUILD_RESULT}

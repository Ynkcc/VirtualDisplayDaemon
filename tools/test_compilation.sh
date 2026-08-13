#!/bin/bash

# This script tests the compilation of the daemon patches by:
# 1. Ensuring the scrcpy submodule is initialized.
# 2. Calling tools/apply_patches.sh to reset and re-apply every patch.
# 3. Running the Gradle build for the server inside the submodule.
#
# Patch application logic lives in apply_patches.sh so both scripts stay
# in sync — no duplicated find/git-apply loops to drift apart.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && git rev-parse --show-toplevel)"
SCRCPY_DIR="${REPO_ROOT}/scrcpy"

echo "Repository Root: ${REPO_ROOT}"
echo "Scrcpy Submodule: ${SCRCPY_DIR}"

if [ ! -d "${SCRCPY_DIR}" ]; then
    echo "Error: scrcpy directory not found: ${SCRCPY_DIR}"
    exit 1
fi

if [ ! -f "${REPO_ROOT}/tools/apply_patches.sh" ]; then
    echo "Error: tools/apply_patches.sh not found — refusing to duplicate patch logic here"
    exit 1
fi

# Make sure the local submodule is initialized before patching it in place.
echo
echo "=== Initializing submodules ==="
git -C "${REPO_ROOT}" submodule update --init --recursive

# Delegate reset + patch application to the single source of truth.
echo
bash "${REPO_ROOT}/tools/apply_patches.sh"

# Ensure local.properties exists for Gradle.
echo
if [ -z "${ANDROID_HOME:-}" ]; then
    echo "Warning: ANDROID_HOME is not set — Gradle may fail to find the SDK"
fi
echo "sdk.dir=${ANDROID_HOME:-}" > "${SCRCPY_DIR}/local.properties"

# Build the server component.
echo
echo "=== Starting Gradle build for scrcpy server ==="
chmod +x "${SCRCPY_DIR}/gradlew"
(cd "${SCRCPY_DIR}" && ./gradlew :server:assembleDebug)

echo
echo "------------------------------------------------"
echo "SUCCESS: The patches compile correctly on scrcpy submodule."
echo "------------------------------------------------"

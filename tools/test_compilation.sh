#!/bin/bash

# This script tests the compilation of the daemon patches by:
# 1. Resetting the local scrcpy checkout.
# 2. Applying the patches from the current 'patches_queue' directory to the local submodule.
# 3. Running the Gradle build for the server inside the submodule.

# Exit on error
set -e

# Get the absolute path of the current repository
REPO_ROOT=$(git rev-parse --show-toplevel)
PATCHES_QUEUE_DIR="${REPO_ROOT}/patches_queue"

echo "Repository Root: ${REPO_ROOT}"
echo "Patches Queue: ${PATCHES_QUEUE_DIR}"

if [ ! -d "${PATCHES_QUEUE_DIR}" ]; then
    echo "Error: Patches directory not found: ${PATCHES_QUEUE_DIR}"
    exit 1
fi

SCRCPY_DIR="${REPO_ROOT}/scrcpy"

if [ ! -d "${SCRCPY_DIR}" ]; then
    echo "Error: scrcpy directory not found: ${SCRCPY_DIR}"
    exit 1
fi

# Make sure the local submodule is initialized before patching it in place.
git -C "${REPO_ROOT}" submodule update --init --recursive

cd "${SCRCPY_DIR}"

# Restore the local scrcpy checkout before reapplying patches.
echo "Resetting local scrcpy checkout..."
git reset --hard
git clean -fd

# Ensure local.properties exists for Gradle
echo "sdk.dir=$ANDROID_HOME" > local.properties

# Apply all patches from the source patches_queue
echo "Applying patches..."

# 1. Apply gradlew.patch if it exists (at the root of scrcpy)
if [ -f "${PATCHES_QUEUE_DIR}/gradlew.patch" ]; then
    echo "Applying gradlew.patch..."
    git apply --recount --verbose "${PATCHES_QUEUE_DIR}/gradlew.patch"
fi

# 2. Apply server patches
# The server patches are expected to be relative to the scrcpy root (start with server/)
# We use 'git apply --recount' which is much more robust than the 'patch' utility.
find "${PATCHES_QUEUE_DIR}/server" -name "*.patch" | sort | while read patch_path; do
    echo "Applying $(basename "${patch_path}")..."
    git apply --recount --verbose "${patch_path}"
done

echo "Starting Gradle build for scrcpy server..."
# Ensure gradlew is executable (it might have been patched)
chmod +x ./gradlew

# Build the server component
./gradlew :server:assembleDebug

BUILD_RESULT=$?

if [ ${BUILD_RESULT} -eq 0 ]; then
    echo "------------------------------------------------"
    echo "SUCCESS: The patches compile correctly on scrcpy submodule."
    echo "------------------------------------------------"
else
    echo "------------------------------------------------"
    echo "FAILURE: Compilation failed."
    echo "------------------------------------------------"
fi

exit ${BUILD_RESULT}

#!/bin/bash
TARGET_FILE=$1
JAVA_FILE=$2
echo "diff --git a/${TARGET_FILE} b/${TARGET_FILE}"
echo "new file mode 100644"
echo "--- /dev/null"
echo "+++ b/${TARGET_FILE}"
LINE_COUNT=$(wc -l < "${JAVA_FILE}")
echo "@@ -0,0 +1,${LINE_COUNT} @@"
sed 's/^/+/' "${JAVA_FILE}"

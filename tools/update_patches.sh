#!/bin/bash

cd scrcpy && git add -A && for f in $(find ../patches_queue -name "*.patch"); do
    rel_path=${f#../patches_queue/}
    rel_path=${rel_path%.patch}

    if [ -f "$rel_path" ]; then
        git diff --cached -- "$rel_path" > "$f"
    fi
done
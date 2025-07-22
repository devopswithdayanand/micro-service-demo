#!/bin/bash

# Ensure full history is available (unshallow if needed)
git fetch --unshallow 2>/dev/null || git fetch --all

# Determine comparison baseline: use origin/main if HEAD~1 is missing
if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
  COMPARE_BASE="HEAD~1"
else
  COMPARE_BASE="origin/main"
fi

changed_services=()

for dir in src/*/ ; do
  if git diff --quiet "$COMPARE_BASE" HEAD -- "$dir"; then
    continue
  else
    changed_services+=("$(basename "$dir")")
  fi
done

# Output unique service names
echo "${changed_services[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '

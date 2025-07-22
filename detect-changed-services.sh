#!/bin/bash

# Ensure full history is available
git fetch --unshallow 2>/dev/null || git fetch --all

# Set comparison base
if git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
  COMPARE_BASE="HEAD~1"
else
  COMPARE_BASE="origin/main"
fi

echo "COMPARE_BASE=${COMPARE_BASE}"

changed_services=()

for dir in src/*/ ; do
  if git diff --quiet "$COMPARE_BASE" HEAD -- "$dir"; then
    continue
  else
    changed_services+=("$(basename "$dir")")
  fi
done

# Output changed service names
echo "${changed_services[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '

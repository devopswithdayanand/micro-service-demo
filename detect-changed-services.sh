#!/bin/bash

# Script to detect changed microservices inside the src/ directory
# It compares current commit with the previous commit (HEAD~1)

changed_services=()

# Loop through each subdirectory under src/
for dir in src/*/ ; do
    # Check if any files in this directory changed between HEAD~1 and HEAD
    if git diff --quiet HEAD~1 HEAD -- "$dir"; then
        continue  # No changes
    else
        # Remove trailing slash and add the service name to the list
        changed_services+=("$(basename "$dir")")
    fi
done

# Print the space-separated list of changed services
echo "${changed_services[@]}"

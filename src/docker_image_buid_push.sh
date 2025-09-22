#!/usr/bin/env bash

set -euo pipefail

# ------------ config (change if needed) ------------
DOCKERHUB_USER="${DOCKERHUB_USER:-devopswithdayanand}"
TAG="${TAG:-$(git rev-parse --short HEAD 2>/dev/null || date +%s)}"
# --------------------------------------------------

log() { printf "\n[ %s ] %s\n" "$(date '+%H:%M:%S')" "$*"; }

# find directories (one level) that contain a Dockerfile
mapfile -t SERVICES < <(find . -maxdepth 2 -type f -iname Dockerfile -print \
  | sed -E 's|/Dockerfile$||' | sed 's|^\./||' | sort)

if [[ ${#SERVICES[@]} -eq 0 ]]; then
  echo "No Dockerfiles found. Put Dockerfile in service folders (e.g. ./service-auth/Dockerfile)."
  exit 1
fi

log "Found ${#SERVICES[@]} services. Using DockerHub user: ${DOCKERHUB_USER}, tag: ${TAG}"

# DockerHub login (non-interactive if DOCKERHUB_PASSWORD provided)
if [[ -n "${DOCKERHUB_PASSWORD:-}" ]]; then
  echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USER" --password-stdin
else
  log "No DOCKERHUB_PASSWORD env var — running interactive docker login"
  docker login --username "$DOCKERHUB_USER"
fi

# iterate and build/push
for dir in "${SERVICES[@]}"; do
  svc="$(basename "$dir")"
  full_image="${DOCKERHUB_USER}/${svc}:${TAG}"

  log "Building service '${svc}' from '${dir}'"
  docker build -t "${svc}:local" "${dir}"

  log "Tagging ${svc}:local → ${full_image}"
  docker tag "${svc}:local" "${full_image}"

  log "Pushing ${full_image}"
  docker push "${full_image}"

  log "Finished ${full_image}"
done

log "All done. Pushed ${#SERVICES[@]} images with tag=${TAG}"

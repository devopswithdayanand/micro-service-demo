#!/usr/bin/env bash
# scripts/simple-build-and-push.sh
# Simple script: build and push every folder that has a Dockerfile (one level deep)
#
# Usage:
#   from repo root:
#     ./scripts/simple-build-and-push.sh
#   optional:
#     TAG=release-123 ./scripts/simple-build-and-push.sh
#   non-interactive login:
#     DOCKERHUB_PASSWORD=ghp_xxx ./scripts/simple-build-and-push.sh

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
if [[ -n "${DOCKERHUB_PASSWORD:-dckr_pat_qs31blWlEcXnT4tmrnwgnkZPcu8}" ]]; then
  echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USER" --password-stdin
else
  log "No DOCKERHUB_PASSWORD env var — running interactive docker login"
  docker login --username "$DOCKERHUB_USER"
fi

# iterate and build/push
# set PUSH_LATEST=1 to push :latest as well; set to 0 to skip
PUSH_LATEST="${PUSH_LATEST:-1}"

for dir in "${SERVICES[@]}"; do
  svc="$(basename "$dir")"
  full_image="${DOCKERHUB_USER}/${svc}:${TAG}"
  latest_image="${DOCKERHUB_USER}/${svc}:latest"
  local_tag="${svc}:local"

  log "Building service '${svc}' from '${dir}'"
  docker build -t "${local_tag}" "${dir}"

  # tag & push the immutable/tagged image
  log "Tagging ${local_tag} → ${full_image}"
  docker tag "${local_tag}" "${full_image}"
  log "Pushing ${full_image}"
  docker push "${full_image}"

  # optionally tag & push :latest (overwrites last latest)
  if [[ "${PUSH_LATEST}" == "1" ]]; then
    log "Tagging ${local_tag} → ${latest_image}"
    docker tag "${local_tag}" "${latest_image}"
    log "Pushing ${latest_image}"
    docker push "${latest_image}"
  else
    log "Skipping push of :latest for ${svc} (PUSH_LATEST=${PUSH_LATEST})"
  fi

  log "Finished ${svc} (pushed tags: ${TAG} ${PUSH_LATEST:+and latest})"
done


log "All done. Pushed ${#SERVICES[@]} images with tag=${TAG}"

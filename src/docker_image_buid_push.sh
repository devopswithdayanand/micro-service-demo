#!/bin/bash
# src/docker_image_buid_push.sh
# Builds and pushes all Docker images under src/*/Dockerfile to AWS ECR
# Tags each image with both commit SHA and latest
# Pushes all commit tags first, then latest tags at the end

set -e

AWS_REGION="ap-northeast-1"
AWS_ACCOUNT_ID="395563380578"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
TAG=$(git rev-parse --short HEAD 2>/dev/null || date +%s)

echo "🔹 Logging in to Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"

echo "🔹 Searching for Dockerfiles in ./src/"
mapfile -t DOCKERFILES < <(find src -type f -name Dockerfile)

if [ ${#DOCKERFILES[@]} -eq 0 ]; then
  echo "❌ No Dockerfiles found under src/. Expected: src/<service>/Dockerfile"
  exit 1
fi

echo "🔹 Found ${#DOCKERFILES[@]} services."
IMAGES=()

# Step 1: Build and tag each image
for dockerfile in "${DOCKERFILES[@]}"; do
  service=$(basename "$(dirname "$dockerfile")")
  image="${ECR_URI}/${service}:${TAG}"
  latest="${ECR_URI}/${service}:latest"
  IMAGES+=("$service")

  echo "🚀 Building image for ${service}"
  docker build -t "$image" "$(dirname "$dockerfile")"
  docker tag "$image" "$latest"
done

# Step 2: Push all <commit> tags
echo "🔹 Pushing all images with tag ${TAG}"
for service in "${IMAGES[@]}"; do
  image="${ECR_URI}/${service}:${TAG}"
  echo "⬆️  Pushing ${image}"
  docker push "$image"
done

# Step 3: Push all :latest tags at the end
echo "🔹 Pushing all :latest tags"
for service in "${IMAGES[@]}"; do
  latest="${ECR_URI}/${service}:latest"
  echo "⬆️  Pushing ${latest}"
  docker push "$latest"
done

echo "🎉 All ${#IMAGES[@]} services pushed successfully to ${ECR_URI}"
echo "   Tags pushed: ${TAG} and latest"

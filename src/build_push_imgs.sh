#!/bin/bash
# Simple script to build and push all microservice Docker images to AWS ECR
# Works for structure: src/<service>/Dockerfile
# Builds -> Pushes all commit tags -> Then pushes all :latest tags

set -e

AWS_REGION="ap-northeast-1"
AWS_ACCOUNT_ID="395563380578"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
TAG=$(git rev-parse --short HEAD 2>/dev/null || date +%s)

echo "🔹 Logging into Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"

# Step 1: Find all Dockerfiles under src/
echo "🔹 Searching for Dockerfiles in ./src/"
mapfile -t DOCKERFILES < <(find src -type f -name Dockerfile)

if [ ${#DOCKERFILES[@]} -eq 0 ]; then
  echo "❌ No Dockerfiles found under src/. Expected structure: src/<service>/Dockerfile"
  exit 1
fi

echo "🔹 Found ${#DOCKERFILES[@]} services."
IMAGES=()

# Step 2: Build all services and tag with commit SHA
for dockerfile in "${DOCKERFILES[@]}"; do
  service=$(basename "$(dirname "$dockerfile")")
  image="${ECR_URI}/${service}:${TAG}"
  latest="${ECR_URI}/${service}:latest"
  IMAGES+=("$service")

  echo "🚀 Building image for ${service}"
  docker build -t "$image" "$(dirname "$dockerfile")"

  # Tag image as latest but push later
  docker tag "$image" "$latest"

  echo "✅ Built and tagged: $image"
done

# Step 3: Push all commit-tagged images
echo "🔹 Pushing all images with tag: ${TAG}"
for service in "${IMAGES[@]}"; do
  image="${ECR_URI}/${service}:${TAG}"
  echo "⬆️  Pushing ${image}"
  docker push "$image"
done

# Step 4: Push all :latest tags at the end
echo "🔹 Now pushing all :latest tags"
for service in "${IMAGES[@]}"; do
  latest="${ECR_URI}/${service}:latest"
  echo "⬆️  Pushing ${latest}"
  docker push "$latest"
done

echo "🎉 All ${#IMAGES[@]} services pushed successfully to ${ECR_URI}"
echo "   Tags pushed: ${TAG} and latest"

#!/usr/bin/env bash
# Usage: ./scripts/build.sh <environment> <version>
# Example: HOST_PORT=8081 ./scripts/build.sh dev v1.0.0
#
# Notes:
# - Set HOST_PORT env var to request a host port (default: 8081).
# - Script will auto-pick a free port in range 8081..8181 if requested port is busy.
# - Set SKIP_PUSH=1 to skip pushing to Docker Hub.
# - Use DOCKERHUB_USERNAME and DOCKERHUB_TOKEN (or a .env) for pushing.

set -euo pipefail

# helpers
print_info()    { echo "[INFO] $*"; }
print_success() { echo "[SUCCESS] $*"; }
print_error()   { echo "[ERROR] $*" >&2; }
print_warning() { echo "[WARNING] $*"; }

usage() {
  cat <<EOF
Usage: $0 <environment> <version>

environment: dev | prod
version: e.g. v1.0.0

Optional env vars:
  HOST_PORT           Host port to map to container:80 (default: 8081)
  SKIP_PUSH=1         Skip pushing to Docker Hub
  DOCKERHUB_USERNAME  Docker Hub username
  DOCKERHUB_TOKEN     Docker Hub token/password

Example:
  HOST_PORT=8081 ./scripts/build.sh dev v1.0.0
EOF
  exit 1
}

# arg check
if [ $# -ne 2 ]; then
  print_error "Invalid number of arguments"
  usage
fi

ENVIRONMENT=$1
VERSION=$2

if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
  print_error "Environment must be 'dev' or 'prod'"
  usage
fi

# load .env (if present)
if [ -f .env ]; then
  print_info "Loading environment variables from .env"
  set -o allexport
  # shellcheck disable=SC1090
  source <(grep -v '^\s*#' .env | sed -E '/^\s*$/d') || true
  set +o allexport
else
  print_warning ".env file not found. Using default values."
fi

# repo selection
DOCKER_REPO=${DOCKERHUB_DEV_REPO:-"abhishek8056/dev"}
if [ "$ENVIRONMENT" = "prod" ]; then
  DOCKER_REPO=${DOCKERHUB_PROD_REPO:-"abhishek8056/prod"}
fi

IMAGE_NAME="${DOCKER_REPO}:${VERSION}"
IMAGE_LATEST="${DOCKER_REPO}:latest"

# requested host port (may be overridden by auto-pick)
REQUESTED_HOST_PORT="${HOST_PORT:-8081}"

# helper: check port listen status (returns 0 if port is in use)
port_listening() {
  local port=$1
  if command -v ss >/dev/null 2>&1; then
    ss -ltn "( sport = :$port )" 2>/dev/null | grep -q LISTEN && return 0 || return 1
  elif command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && return 0 || return 1
  else
    # no reliable check tool — optimistically treat as free
    return 1
  fi
}

# helper: find free port starting at given port up to max_port
find_free_port_from() {
  local start=${1:-8081}
  local max=8181
  local port=$start

  while [ "$port" -le "$max" ]; do
    if ! port_listening "$port"; then
      echo "$port"
      return 0
    fi
    port=$((port + 1))
  done

  return 1
}

# choose host port (respect requested if free, otherwise auto-pick)
if ! port_listening "$REQUESTED_HOST_PORT"; then
  HOST_PORT="$REQUESTED_HOST_PORT"
else
  FREE_PORT=$(find_free_port_from "$REQUESTED_HOST_PORT") || {
    print_error "Couldn't find a free host port in range ${REQUESTED_HOST_PORT}-8181. Export HOST_PORT to another value."
    exit 1
  }
  print_warning "Requested HOST_PORT ${REQUESTED_HOST_PORT} is in use — falling back to ${FREE_PORT}"
  HOST_PORT="$FREE_PORT"
fi

print_info "=========================================="
print_info "Docker Build Configuration"
print_info "Environment: $ENVIRONMENT"
print_info "Version: $VERSION"
print_info "Image Name: $IMAGE_NAME"
print_info "Image Latest: $IMAGE_LATEST"
print_info "Host Port (test): $HOST_PORT"
print_info "=========================================="

# ensure docker running
if ! docker info > /dev/null 2>&1; then
  print_error "Docker is not running. Please start Docker and try again."
  exit 1
fi
print_success "Docker is running"

# sanity checks
[ -f "Dockerfile" ] || { print_error "Dockerfile not found"; exit 1; }
print_success "Dockerfile found"
[ -d "build" ] || { print_error "build/ directory not found. Please ensure pre-built React app exists."; exit 1; }
print_success "Pre-built React app found in build/ directory"

# build image
print_info "Building Docker image (this may take a few minutes)..."
BUILD_START_TS=$(date +%s)
docker build --pull -t "$IMAGE_NAME" -t "$IMAGE_LATEST" .
BUILD_END_TS=$(date +%s)
BUILD_SECONDS=$((BUILD_END_TS - BUILD_START_TS))
print_success "Docker image built in ${BUILD_SECONDS} seconds"

# image size (best-effort)
IMAGE_SIZE=$(docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | awk -v img="${IMAGE_NAME}" '$1==img{print $2; exit}' || true)
print_info "Image size: ${IMAGE_SIZE:-unknown}"

# verify image exists
if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${DOCKER_REPO}:${VERSION}$"; then
  print_error "Image not found in local Docker registry"
  exit 1
fi
print_success "Image verified in local Docker registry"

# Test the image locally
print_info "Testing image locally..."
TEST_NAME="test-${ENVIRONMENT}-${VERSION//[:\/]/-}-$RANDOM"

cleanup() {
  # only stop/remove our test container
  if docker ps -a --format '{{.Names}}' | grep -q "^${TEST_NAME}$"; then
    print_info "Cleaning up test container ${TEST_NAME}..."
    docker stop "$TEST_NAME" >/dev/null 2>&1 || true
    docker rm "$TEST_NAME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

CONTAINER_ID=$(docker run -d -p "${HOST_PORT}:80" --name "$TEST_NAME" "$IMAGE_NAME" 2>/dev/null || true)
if [ -z "$CONTAINER_ID" ]; then
  print_error "Failed to start test container. Inspect docker ps -a for details."
  docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' | sed -n '1,50p'
  exit 1
fi

print_info "Test container started: $CONTAINER_ID (host:${HOST_PORT} -> container:80)"
print_info "Waiting for the app to become ready..."
sleep 5

if command -v curl >/dev/null 2>&1; then
  if curl -sf "http://localhost:${HOST_PORT}" >/dev/null 2>&1; then
    print_success "Application is responding on port ${HOST_PORT}"
  else
    print_warning "Application not responding on port ${HOST_PORT}. Showing last 200 container log lines:"
    docker logs "$CONTAINER_ID" --tail 200 || true
  fi
else
  print_warning "curl not available; skipping HTTP check"
fi

# stop & cleanup test container
docker stop "$CONTAINER_ID" >/dev/null 2>&1 || true
docker rm "$CONTAINER_ID" >/dev/null 2>&1 || true
print_success "Test container cleaned up"

# optionally push to Docker Hub
if [ "${SKIP_PUSH:-0}" = "1" ]; then
  print_info "SKIP_PUSH=1 set; skipping Docker Hub push"
else
  print_info "Logging in to Docker Hub (if credentials available)..."
  if [ -n "${DOCKERHUB_USERNAME:-}" ] && [ -n "${DOCKERHUB_TOKEN:-}" ]; then
    echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
    print_success "Logged in to Docker Hub"
  else
    print_warning "DOCKERHUB_USERNAME/DOCKERHUB_TOKEN not set; using existing docker credentials (if any)"
  fi

  print_info "Pushing ${IMAGE_NAME}..."
  if docker push "$IMAGE_NAME"; then
    print_success "Pushed ${IMAGE_NAME}"
  else
    print_error "Failed to push ${IMAGE_NAME}"
    exit 1
  fi

  print_info "Pushing ${IMAGE_LATEST}..."
  if docker push "$IMAGE_LATEST"; then
    print_success "Pushed ${IMAGE_LATEST}"
  else
    print_error "Failed to push ${IMAGE_LATEST}"
    exit 1
  fi
fi

# metadata & logs
BUILD_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

mkdir -p build-logs
BUILD_LOG="build-logs/build-${ENVIRONMENT}-${VERSION}-$(date +%Y%m%d-%H%M%S).log"
cat > "$BUILD_LOG" <<EOF
{
  "buildTimestamp": "$BUILD_TIMESTAMP",
  "buildDurationSeconds": "$BUILD_SECONDS",
  "gitCommit": "$GIT_COMMIT",
  "gitBranch": "$GIT_BRANCH",
  "dockerImage": "$IMAGE_NAME",
  "environment": "$ENVIRONMENT",
  "version": "$VERSION",
  "imageSize": "$IMAGE_SIZE",
  "hostPort": "$HOST_PORT"
}
EOF

print_success "Build metadata saved to $BUILD_LOG"
print_success "Build completed successfully!"
print_info "Image: $IMAGE_NAME"
print_info "Host port (test): $HOST_PORT"
exit 0

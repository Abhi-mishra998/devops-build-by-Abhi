
#!/bin/bash

# Deployment Script for EC2
# Usage: ./scripts/deploy.sh <environment> <version>
# Example: ./scripts/deploy.sh dev v1.0.0

set -e  # Exit on error

# Function to print output
print_info() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_error() {
    echo "[ERROR] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

# Function to display usage
usage() {
    echo "Usage: $0 <environment> <version>"
    echo ""
    echo "Arguments:"
    echo "  environment    Environment to deploy to (dev or prod)"
    echo "  version        Version tag to deploy (e.g., v1.0.0 or latest)"
    echo ""
    echo "Example:"
    echo "  $0 dev v1.0.0"
    echo "  $0 prod latest"
    exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
    print_error "Invalid number of arguments"
    usage
=======
#!/usr/bin/env bash
# Usage: ./scripts/deploy.sh <environment> <version>
# Example: HOST_PORT=8081 ./scripts/deploy.sh dev v1.0.0
#
# Notes:
# - Set HOST_PORT env var to request a host port (default: 8081).
# - Script will auto-pick a free port in range 8081..8181 if requested port is busy.
# - Set SKIP_PULL=1 to skip pulling from Docker Hub.
# - Use DOCKERHUB_USERNAME and DOCKERHUB_TOKEN (or a .env) for pulling.

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
  SKIP_PULL=1         Skip pulling from Docker Hub
  DOCKERHUB_USERNAME  Docker Hub username
  DOCKERHUB_TOKEN     Docker Hub token/password

Example:
  HOST_PORT=8081 ./scripts/deploy.sh dev v1.0.0
EOF
  exit 1
}

# arg check
if [ $# -ne 2 ]; then
  print_error "Invalid number of arguments"
  usage
>>>>>>> main
fi

ENVIRONMENT=$1
VERSION=$2

<<<<<<< HEAD
# Validate environment
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    print_error "Environment must be 'dev' or 'prod'"
    usage
fi

# Load environment variables
if [ -f .env ]; then
    print_info "Loading environment variables from .env file"
    export $(cat .env | grep -v '^#' | xargs)
else
    print_error ".env file not found. Please run ./scripts/configure.sh first."
    exit 1
fi

# Validate required environment variables
if [ -z "$EC2_PUBLIC_IP" ] || [ -z "$EC2_USER" ] || [ -z "$EC2_KEY_PATH" ]; then
    print_error "Missing required environment variables"
    print_error "Please ensure EC2_PUBLIC_IP, EC2_USER, and EC2_KEY_PATH are set in .env"
    exit 1
fi

# Set Docker Hub repository based on environment
if [ "$ENVIRONMENT" == "dev" ]; then
    DOCKER_REPO=${DOCKERHUB_DEV_REPO:-"username/dev"}
else
    DOCKER_REPO=${DOCKERHUB_PROD_REPO:-"username/prod"}
fi

IMAGE_NAME="${DOCKER_REPO}:${VERSION}"
CONTAINER_NAME="react-app-${ENVIRONMENT}"

print_info "=========================================="
print_info "Deployment Configuration"
print_info "=========================================="
print_info "Environment: $ENVIRONMENT"
print_info "Version: $VERSION"
print_info "Image: $IMAGE_NAME"
print_info "EC2 Instance: $EC2_PUBLIC_IP"
print_info "Container Name: $CONTAINER_NAME"
print_info "=========================================="

# Check if SSH key exists
if [ ! -f "$EC2_KEY_PATH" ]; then
    print_error "SSH key not found at: $EC2_KEY_PATH"
    exit 1
fi

print_success "SSH key found"

# Test SSH connection
print_info "Testing SSH connection to EC2 instance..."
if ssh -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$EC2_USER@$EC2_PUBLIC_IP" "echo 'Connection successful'" > /dev/null 2>&1; then
    print_success "SSH connection successful"
else
    print_error "Failed to connect to EC2 instance"
    print_error "Please check:"
    print_error "  - EC2 instance is running"
    print_error "  - Security Group allows SSH from your IP"
    print_error "  - SSH key has correct permissions (chmod 400)"
    exit 1
fi

# Create deployment script to run on EC2
DEPLOY_SCRIPT=$(cat << 'EOF'
#!/bin/bash
set -e

IMAGE_NAME="$1"
CONTAINER_NAME="$2"
DOCKERHUB_USERNAME="$3"
DOCKERHUB_TOKEN="$4"

echo "[INFO] Starting deployment on EC2..."

# Login to Docker Hub
echo "[INFO] Logging in to Docker Hub..."
echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin

# Pull latest image
echo "[INFO] Pulling Docker image: $IMAGE_NAME"
docker pull "$IMAGE_NAME"

# Check if container exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "[INFO] Stopping existing container: $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME" || true
    
    echo "[INFO] Removing existing container: $CONTAINER_NAME"
    docker rm "$CONTAINER_NAME" || true
fi

# Start new container
echo "[INFO] Starting new container: $CONTAINER_NAME"
docker run -d \
    --name "$CONTAINER_NAME" \
    -p 80:80 \
    --restart unless-stopped \
    "$IMAGE_NAME"

# Wait for container to be ready
echo "[INFO] Waiting for container to be ready..."
sleep 5

# Verify container is running
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "[SUCCESS] Container is running"
    
    # Test application
    if curl -f http://localhost > /dev/null 2>&1; then
        echo "[SUCCESS] Application is responding"
    else
        echo "[WARNING] Application not responding yet"
    fi
else
    echo "[ERROR] Container failed to start"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Clean up old images
echo "[INFO] Cleaning up old Docker images..."
docker image prune -f

echo "[SUCCESS] Deployment completed successfully!"
EOF
)

# Deploy to EC2
print_info "Deploying to EC2 instance..."
print_info "This may take a few minutes..."

DEPLOY_START=$(date +%s)

# Execute deployment script on EC2
if ssh -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_PUBLIC_IP" "bash -s" -- "$IMAGE_NAME" "$CONTAINER_NAME" "$DOCKERHUB_USERNAME" "$DOCKERHUB_TOKEN" <<< "$DEPLOY_SCRIPT"; then
    DEPLOY_END=$(date +%s)
    DEPLOY_TIME=$((DEPLOY_END - DEPLOY_START))
    print_success "Deployment completed in ${DEPLOY_TIME} seconds"
else
    print_error "Deployment failed"
    exit 1
fi

# Verify deployment
print_info "Verifying deployment..."
sleep 3

if curl -f "http://$EC2_PUBLIC_IP" > /dev/null 2>&1; then
    print_success "Application is accessible at http://$EC2_PUBLIC_IP"
else
    print_warning "Application may not be accessible yet. Please check manually."
fi

# Get container status
print_info "Getting container status..."
CONTAINER_STATUS=$(ssh -i "$EC2_KEY_PATH" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_PUBLIC_IP" "docker ps --filter name=$CONTAINER_NAME --format '{{.Status}}'")
print_info "Container Status: $CONTAINER_STATUS"

# Create deployment log
DEPLOY_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

print_info "=========================================="
print_info "Deployment Summary"
print_info "=========================================="
print_info "Deploy Time: $DEPLOY_TIME"
print_info "Git Commit: $GIT_COMMIT"
print_info "Environment: $ENVIRONMENT"
print_info "Version: $VERSION"
print_info "Image: $IMAGE_NAME"
print_info "EC2 Instance: $EC2_PUBLIC_IP"
print_info "Application URL: http://$EC2_PUBLIC_IP"
print_info "=========================================="

# Save deployment metadata
mkdir -p deploy-logs
DEPLOY_LOG="deploy-logs/deploy-${ENVIRONMENT}-${VERSION}-$(date +%Y%m%d-%H%M%S).log"
cat > "$DEPLOY_LOG" << EOF
{
  "deployTime": "$DEPLOY_TIME",
  "gitCommit": "$GIT_COMMIT",
  "environment": "$ENVIRONMENT",
  "version": "$VERSION",
  "dockerImage": "$IMAGE_NAME",
  "ec2Instance": "$EC2_PUBLIC_IP",
  "applicationUrl": "http://$EC2_PUBLIC_IP",
  "containerStatus": "$CONTAINER_STATUS"
}
EOF

print_success "Deployment metadata saved to $DEPLOY_LOG"

print_success "=========================================="
print_success "Deployment completed successfully!"
print_success "=========================================="
print_info "Application URL: http://$EC2_PUBLIC_IP"
print_info "Container: $CONTAINER_NAME"
print_info "Status: Running"
print_success "=========================================="

=======
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
print_info "Docker Deploy Configuration"
print_info "Environment: $ENVIRONMENT"
print_info "Version: $VERSION"
print_info "Image Name: $IMAGE_NAME"
print_info "Host Port: $HOST_PORT"
print_info "=========================================="

# ensure docker running
if ! docker info > /dev/null 2>&1; then
  print_error "Docker is not running. Please start Docker and try again."
  exit 1
fi
print_success "Docker is running"

# optionally pull from Docker Hub
if [ "${SKIP_PULL:-0}" = "1" ]; then
  print_info "SKIP_PULL=1 set; skipping Docker Hub pull"
else
  print_info "Logging in to Docker Hub (if credentials available)..."
  if [ -n "${DOCKERHUB_USERNAME:-}" ] && [ -n "${DOCKERHUB_TOKEN:-}" ]; then
    echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
    print_success "Logged in to Docker Hub"
  else
    print_warning "DOCKERHUB_USERNAME/DOCKERHUB_TOKEN not set; using existing docker credentials (if any)"
  fi

  print_info "Pulling ${IMAGE_NAME}..."
  if docker pull "$IMAGE_NAME"; then
    print_success "Pulled ${IMAGE_NAME}"
  else
    print_error "Failed to pull ${IMAGE_NAME}"
    exit 1
  fi
fi

# verify image exists
if ! docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${DOCKER_REPO}:${VERSION}$"; then
  print_error "Image not found in local Docker registry"
  exit 1
fi
print_success "Image verified in local Docker registry"

# Deploy the image locally
print_info "Deploying image locally..."
DEPLOY_START_TS=$(date +%s)
DEPLOY_NAME="deploy-${ENVIRONMENT}-${VERSION//[:\/]/-}-$RANDOM"

cleanup() {
  # only stop/remove our deploy container
  if docker ps -a --format '{{.Names}}' | grep -q "^${DEPLOY_NAME}$"; then
    print_info "Cleaning up deploy container ${DEPLOY_NAME}..."
    docker stop "$DEPLOY_NAME" >/dev/null 2>&1 || true
    docker rm "$DEPLOY_NAME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

CONTAINER_ID=$(docker run -d -p "${HOST_PORT}:80" --name "$DEPLOY_NAME" "$IMAGE_NAME" 2>/dev/null || true)
if [ -z "$CONTAINER_ID" ]; then
  print_error "Failed to start deploy container. Inspect docker ps -a for details."
  docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' | sed -n '1,50p'
  exit 1
fi

print_info "Deploy container started: $CONTAINER_ID (host:${HOST_PORT} -> container:80)"
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

DEPLOY_END_TS=$(date +%s)
DEPLOY_SECONDS=$((DEPLOY_END_TS - DEPLOY_START_TS))
print_success "Deployment completed in ${DEPLOY_SECONDS} seconds"

# image size (best-effort)
IMAGE_SIZE=$(docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | awk -v img="${IMAGE_NAME}" '$1==img{print $2; exit}' || true)
print_info "Image size: ${IMAGE_SIZE:-unknown}"

# metadata & logs
DEPLOY_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

mkdir -p deploy-logs
DEPLOY_LOG="deploy-logs/deploy-${ENVIRONMENT}-${VERSION}-$(date +%Y%m%d-%H%M%S).log"
cat > "$DEPLOY_LOG" <<EOF
{
  "deployTimestamp": "$DEPLOY_TIMESTAMP",
  "deployDurationSeconds": "$DEPLOY_SECONDS",
  "gitCommit": "$GIT_COMMIT",
  "gitBranch": "$GIT_BRANCH",
  "dockerImage": "$IMAGE_NAME",
  "environment": "$ENVIRONMENT",
  "version": "$VERSION",
  "imageSize": "$IMAGE_SIZE",
  "hostPort": "$HOST_PORT"
}
EOF

print_success "Deploy metadata saved to $DEPLOY_LOG"
print_success "Deployment completed successfully!"
print_info "Image: $IMAGE_NAME"
print_info "Host port: $HOST_PORT"

exit 0

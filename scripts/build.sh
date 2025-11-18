#!/bin/bash

# Build Script for Docker Images (Pre-built React App)
# Usage: ./scripts/build.sh <environment> <version>
# Example: ./scripts/build.sh dev v1.0.0

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
    echo "  environment    Environment to build for (dev or prod)"
    echo "  version        Version tag for the image (e.g., v1.0.0)"
    echo ""
    echo "Example:"
    echo "  $0 dev v1.0.0"
    echo "  $0 prod v2.1.0"
    exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
    print_error "Invalid number of arguments"
    usage
fi

ENVIRONMENT=$1
VERSION=$2

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
    print_warning ".env file not found. Using default values."
fi

# Set Docker Hub repository based on environment
if [ "$ENVIRONMENT" == "dev" ]; then
    DOCKER_REPO=${DOCKERHUB_DEV_REPO:-"abhishek8056/dev"}
else
    DOCKER_REPO=${DOCKERHUB_PROD_REPO:-"abhishek8056/prod"}
fi

IMAGE_NAME="${DOCKER_REPO}:${VERSION}"
IMAGE_LATEST="${DOCKER_REPO}:latest"

print_info "=========================================="
print_info "Docker Build Configuration"
print_info "=========================================="
print_info "Environment: $ENVIRONMENT"
print_info "Version: $VERSION"
print_info "Image Name: $IMAGE_NAME"
print_info "Image Latest: $IMAGE_LATEST"
print_info "=========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_success "Docker is running"

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found in current directory"
    exit 1
fi

print_success "Dockerfile found"

# Check if build directory exists
if [ ! -d "build" ]; then
    print_error "build/ directory not found. Please ensure pre-built React app exists."
    exit 1
fi

print_success "Pre-built React app found in build/ directory"

# Build Docker image
print_info "Building Docker image..."
print_info "This may take a few minutes..."

BUILD_START=$(date +%s)

if docker build -t "$IMAGE_NAME" -t "$IMAGE_LATEST" .; then
    BUILD_END=$(date +%s)
    BUILD_TIME=$((BUILD_END - BUILD_START))
    print_success "Docker image built successfully in ${BUILD_TIME} seconds"
else
    print_error "Docker build failed"
    exit 1
fi

# Get image size
IMAGE_SIZE=$(docker images "$IMAGE_NAME" --format "{{.Size}}")
print_info "Image size: $IMAGE_SIZE"

# Verify image was created
if docker images | grep -q "$DOCKER_REPO"; then
    print_success "Image verified in local Docker registry"
else
    print_error "Image not found in local Docker registry"
    exit 1
fi

# Test the image locally (optional)
print_info "Testing image locally..."
CONTAINER_ID=$(docker run -d -p 8080:80 "$IMAGE_NAME")

if [ -z "$CONTAINER_ID" ]; then
    print_error "Failed to start test container"
    exit 1
fi

print_info "Test container started with ID: $CONTAINER_ID"
print_info "Waiting for container to be ready..."
sleep 5

# Check if container is running
if docker ps | grep -q "$CONTAINER_ID"; then
    print_success "Container is running"

    # Test HTTP response
    if command -v curl > /dev/null 2>&1; then
        if curl -f http://localhost:8080 > /dev/null 2>&1; then
            print_success "Application is responding on port 8080"
        else
            print_warning "Application not responding on port 8080"
        fi
    fi

    # Stop and remove test container
    print_info "Stopping test container..."
    docker stop "$CONTAINER_ID" > /dev/null 2>&1
    docker rm "$CONTAINER_ID" > /dev/null 2>&1
    print_success "Test container cleaned up"
else
    print_error "Container failed to start"
    docker logs "$CONTAINER_ID"
    docker rm "$CONTAINER_ID" > /dev/null 2>&1
    exit 1
fi

# Login to Docker Hub
print_info "Logging in to Docker Hub..."
if [ -n "$DOCKERHUB_USERNAME" ] && [ -n "$DOCKERHUB_TOKEN" ]; then
    echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
    if [ $? -eq 0 ]; then
        print_success "Logged in to Docker Hub"
    else
        print_error "Failed to login to Docker Hub"
        exit 1
    fi
else
    print_warning "Docker Hub credentials not found in .env file"
    print_info "Attempting to use existing Docker credentials..."
fi

# Push image to Docker Hub
print_info "Pushing image to Docker Hub..."
print_info "Pushing $IMAGE_NAME..."

if docker push "$IMAGE_NAME"; then
    print_success "Successfully pushed $IMAGE_NAME"
else
    print_error "Failed to push $IMAGE_NAME"
    exit 1
fi

print_info "Pushing $IMAGE_LATEST..."
if docker push "$IMAGE_LATEST"; then
    print_success "Successfully pushed $IMAGE_LATEST"
else
    print_error "Failed to push $IMAGE_LATEST"
    exit 1
fi

# Create build metadata
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

print_info "=========================================="
print_info "Build Metadata"
print_info "=========================================="
print_info "Build Time: $BUILD_TIME"
print_info "Git Commit: $GIT_COMMIT"
print_info "Git Branch: $GIT_BRANCH"
print_info "Docker Image: $IMAGE_NAME"
print_info "Environment: $ENVIRONMENT"
print_info "=========================================="

# Save build metadata to file
mkdir -p build-logs
BUILD_LOG="build-logs/build-${ENVIRONMENT}-${VERSION}-$(date +%Y%m%d-%H%M%S).log"
cat > "$BUILD_LOG" << EOF
{
  "buildTime": "$BUILD_TIME",
  "gitCommit": "$GIT_COMMIT",
  "gitBranch": "$GIT_BRANCH",
  "dockerImage": "$IMAGE_NAME",
  "environment": "$ENVIRONMENT",
  "version": "$VERSION",
  "imageSize": "$IMAGE_SIZE"
}
EOF

print_success "Build metadata saved to $BUILD_LOG"

print_success "=========================================="
print_success "Build completed successfully!"
print_success "=========================================="
print_info "Image: $IMAGE_NAME"
print_info "Size: $IMAGE_SIZE"
print_info "Ready for deployment"
print_success "=========================================="

exit 0

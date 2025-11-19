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

exit 0

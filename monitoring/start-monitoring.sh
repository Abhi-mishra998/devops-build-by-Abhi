#!/bin/bash

# Start Monitoring Script
# Usage: ./monitoring/start-monitoring.sh

set -e

echo "========================================"
echo "Starting Monitoring System"
echo "========================================"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "[ERROR] Docker is not running"
    exit 1
fi

echo "[INFO] Docker is running"

# Navigate to monitoring directory
cd monitoring

# Pull latest image
echo "[INFO] Pulling Uptime Kuma image..."
docker-compose pull

# Start monitoring
echo "[INFO] Starting Uptime Kuma..."
docker-compose up -d

# Wait for startup
echo "[INFO] Waiting for startup..."
sleep 10

# Check if running
if docker-compose ps | grep -q "Up"; then
    echo "[SUCCESS] Monitoring system is running"
    echo ""
    echo "Access dashboard: http://localhost:3001"
    echo ""
    echo "Setup Instructions:"
    echo "1. Open http://localhost:3001 in browser"
    echo "2. Create admin account"
    echo "3. Add HTTP monitor for your application"
    echo "4. Configure email notifications"
    echo ""
else
    echo "[ERROR] Failed to start monitoring"
    docker-compose logs
    exit 1
fi

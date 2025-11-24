#!/bin/bash

echo "=== Starting MPI Cluster Setup ==="

# Cleanup existing containers
echo "Cleaning up existing containers..."
docker-compose down 2>/dev/null
docker rm -f node1 node2 node3 2>/dev/null || true

# Build and start containers
echo "Building and starting containers..."
docker-compose up -d --build

# Wait for containers to be ready
echo "Waiting for containers to start..."
sleep 15

# Check container status
echo "Container status:"
docker ps

# Run setup script
echo "Running cluster setup..."
chmod +x scripts/setup-cluster.sh
./scripts/setup-cluster.sh

echo "=== MPI Cluster is ready! ==="
echo "Access node1: docker exec -it node1 sudo -u mpiuser bash"

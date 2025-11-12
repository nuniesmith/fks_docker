#!/bin/bash
# Build script for FKS shared docker base image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Building FKS shared docker base image..."
echo "Repository root: $REPO_ROOT"

cd "$SCRIPT_DIR"

# Build the base image
docker build -t nuniesmith/fks:docker -f Dockerfile.builder .

echo ""
echo "✅ Docker base image built successfully!"
echo ""
echo "Image: nuniesmith/fks:docker"
echo ""
echo "To push to registry:"
echo "  docker push nuniesmith/fks:docker"
echo ""
echo "To use in services, update Dockerfiles to:"
echo "  FROM nuniesmith/fks:docker AS builder"

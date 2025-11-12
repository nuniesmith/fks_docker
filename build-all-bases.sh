#!/bin/bash
# Build all Docker base images locally for testing
# This script builds CPU, ML, and GPU base images in order

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

IMAGE_NAME="nuniesmith/fks"
REGISTRY="${DOCKER_REGISTRY:-docker.io}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=========================================="
echo "FKS Docker Base Images - Local Build"
echo "=========================================="
echo ""

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to build a base image
build_base_image() {
    local name=$1
    local dockerfile=$2
    local tag=$3
    local description=$4
    
    print_status "$YELLOW" "Building $name base image..."
    echo "  Dockerfile: $dockerfile"
    echo "  Tag: $tag"
    echo "  Description: $description"
    echo ""
    
    local start_time=$(date +%s)
    
    if docker build -t "$tag" -f "$dockerfile" .; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local image_size=$(docker images "$tag" --format "{{.Size}}")
        
        print_status "$GREEN" "✅ $name base image built successfully!"
        echo "  Build time: ${duration}s"
        echo "  Image size: $image_size"
        echo "  Tag: $tag"
        echo ""
        
        # Verify the image exists
        if docker image inspect "$tag" > /dev/null 2>&1; then
            print_status "$GREEN" "✅ Image verified: $tag"
        else
            print_status "$RED" "❌ Image verification failed: $tag"
            return 1
        fi
        
        return 0
    else
        print_status "$RED" "❌ $name base image build failed!"
        return 1
    fi
}

# Function to verify base image
verify_base_image() {
    local tag=$1
    local expected_packages=("$@")
    
    print_status "$YELLOW" "Verifying base image: $tag"
    
    # Check if image exists
    if ! docker image inspect "$tag" > /dev/null 2>&1; then
        print_status "$RED" "❌ Image not found: $tag"
        return 1
    fi
    
    # Try to run a test command
    if docker run --rm "$tag" python -c "import sys; print(f'Python {sys.version}')" > /dev/null 2>&1; then
        print_status "$GREEN" "✅ Image can run Python commands"
    else
        print_status "$RED" "❌ Image cannot run Python commands"
        return 1
    fi
    
    return 0
}

# Build CPU base
print_status "$YELLOW" "=== Building CPU Base ==="
if ! build_base_image "CPU" "Dockerfile.builder" "${IMAGE_NAME}:docker" "CPU Base with TA-Lib and build tools"; then
    print_status "$RED" "❌ CPU base build failed. Exiting."
    exit 1
fi

# Verify CPU base
if ! verify_base_image "${IMAGE_NAME}:docker"; then
    print_status "$RED" "❌ CPU base verification failed. Exiting."
    exit 1
fi

# Build ML base (depends on CPU base)
print_status "$YELLOW" "=== Building ML Base ==="
if ! build_base_image "ML" "Dockerfile.ml" "${IMAGE_NAME}:docker-ml" "ML Base with LangChain, ChromaDB, sentence-transformers"; then
    print_status "$RED" "❌ ML base build failed. Exiting."
    exit 1
fi

# Verify ML base
print_status "$YELLOW" "Verifying ML base packages..."
if docker run --rm "${IMAGE_NAME}:docker-ml" python -c "
import langchain
import chromadb
import sentence_transformers
import ollama
import talib
print('✅ ML packages verified')
" > /dev/null 2>&1; then
    print_status "$GREEN" "✅ ML base packages verified"
else
    print_status "$RED" "❌ ML base packages verification failed"
    exit 1
fi

# Build GPU base (depends on ML base)
print_status "$YELLOW" "=== Building GPU Base ==="
if ! build_base_image "GPU" "Dockerfile.gpu" "${IMAGE_NAME}:docker-gpu" "GPU Base with PyTorch, Transformers, training libraries"; then
    print_status "$RED" "❌ GPU base build failed. Exiting."
    exit 1
fi

# Verify GPU base
print_status "$YELLOW" "Verifying GPU base packages..."
if docker run --rm "${IMAGE_NAME}:docker-gpu" python -c "
import torch
import transformers
import stable_baselines3
import gymnasium
print(f'✅ GPU packages verified (PyTorch {torch.__version__})')
" > /dev/null 2>&1; then
    print_status "$GREEN" "✅ GPU base packages verified"
else
    print_status "$RED" "❌ GPU base packages verification failed"
    exit 1
fi

# Summary
echo ""
print_status "$GREEN" "=========================================="
print_status "$GREEN" "All Base Images Built Successfully!"
print_status "$GREEN" "=========================================="
echo ""
echo "Base Images:"
echo "  - ${IMAGE_NAME}:docker (CPU Base)"
echo "  - ${IMAGE_NAME}:docker-ml (ML Base)"
echo "  - ${IMAGE_NAME}:docker-gpu (GPU Base)"
echo ""
echo "Image Sizes:"
docker images "${IMAGE_NAME}:docker" "${IMAGE_NAME}:docker-ml" "${IMAGE_NAME}:docker-gpu" --format "  {{.Repository}}:{{.Tag}} - {{.Size}}"
echo ""
echo "Next Steps:"
echo "  1. Test base images with service builds (run test-service-builds.sh)"
echo "  2. Verify service images work correctly"
echo "  3. Push to DockerHub (if tests pass)"
echo ""


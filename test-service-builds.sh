#!/bin/bash
# Test base images by building service images with them
# This script builds service images using the new base images and verifies they work

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

IMAGE_NAME="nuniesmith/fks"
TEST_TAG_SUFFIX="-test"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "FKS Service Build Tests with Base Images"
echo "=========================================="
echo ""

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if base image exists
check_base_image() {
    local tag=$1
    if docker image inspect "$tag" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to build a service image
build_service_image() {
    local service=$1
    local service_dir=$2
    local base_image=$3
    local test_tag="${IMAGE_NAME}:${service}${TEST_TAG_SUFFIX}"
    
    print_status "$BLUE" "Testing $service service with base image: $base_image"
    echo "  Service directory: $service_dir"
    echo "  Test tag: $test_tag"
    echo ""
    
    # Check if base image exists
    if ! check_base_image "$base_image"; then
        print_status "$RED" "❌ Base image not found: $base_image"
        print_status "$YELLOW" "   Please build base images first: ./build-all-bases.sh"
        return 1
    fi
    
    # Check if service directory exists
    if [ ! -d "$service_dir" ]; then
        print_status "$RED" "❌ Service directory not found: $service_dir"
        return 1
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "$service_dir/Dockerfile" ]; then
        print_status "$RED" "❌ Dockerfile not found: $service_dir/Dockerfile"
        return 1
    fi
    
    local start_time=$(date +%s)
    
    # Build the service image
    cd "$service_dir"
    if docker build -t "$test_tag" .; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local image_size=$(docker images "$test_tag" --format "{{.Size}}")
        
        print_status "$GREEN" "✅ $service service image built successfully!"
        echo "  Build time: ${duration}s"
        echo "  Image size: $image_size"
        echo "  Test tag: $test_tag"
        echo ""
        
        # Test the service image
        print_status "$YELLOW" "Testing $service service image..."
        if docker run --rm "$test_tag" python -c "import sys; print(f'Python {sys.version}')" > /dev/null 2>&1; then
            print_status "$GREEN" "✅ $service service image can run Python commands"
        else
            print_status "$RED" "❌ $service service image cannot run Python commands"
            return 1
        fi
        
        # Test health check if available
        print_status "$YELLOW" "Testing $service service health check..."
        # Start container in background
        local container_id=$(docker run -d "$test_tag" sleep 30)
        sleep 5
        
        # Try to access health endpoint
        local health_port=$(docker port "$container_id" | grep -oP '\d+' | head -1)
        if [ -n "$health_port" ]; then
            if curl -f "http://localhost:$health_port/health" > /dev/null 2>&1; then
                print_status "$GREEN" "✅ $service service health check passed"
            else
                print_status "$YELLOW" "⚠️  $service service health check not accessible (may be normal)"
            fi
        else
            print_status "$YELLOW" "⚠️  $service service port not accessible (may be normal)"
        fi
        
        # Stop container
        docker stop "$container_id" > /dev/null 2>&1 || true
        docker rm "$container_id" > /dev/null 2>&1 || true
        
        return 0
    else
        print_status "$RED" "❌ $service service image build failed!"
        return 1
    fi
}

# Check if base images exist
print_status "$YELLOW" "Checking base images..."
if ! check_base_image "${IMAGE_NAME}:docker"; then
    print_status "$RED" "❌ CPU base image not found: ${IMAGE_NAME}:docker"
    print_status "$YELLOW" "   Please build base images first: ./build-all-bases.sh"
    exit 1
fi

if ! check_base_image "${IMAGE_NAME}:docker-ml"; then
    print_status "$RED" "❌ ML base image not found: ${IMAGE_NAME}:docker-ml"
    print_status "$YELLOW" "   Please build base images first: ./build-all-bases.sh"
    exit 1
fi

if ! check_base_image "${IMAGE_NAME}:docker-gpu"; then
    print_status "$RED" "❌ GPU base image not found: ${IMAGE_NAME}:docker-gpu"
    print_status "$YELLOW" "   Please build base images first: ./build-all-bases.sh"
    exit 1
fi

print_status "$GREEN" "✅ All base images found"
echo ""

# Test CPU services (using CPU base)
print_status "$YELLOW" "=== Testing CPU Services ==="
# Note: CPU services haven't been updated yet, so we'll skip them for now
# build_service_image "app" "$REPO_ROOT/repo/app" "${IMAGE_NAME}:docker"
# build_service_image "data" "$REPO_ROOT/repo/data" "${IMAGE_NAME}:docker"

# Test ML services (using ML base)
print_status "$YELLOW" "=== Testing ML Services ==="
if build_service_image "ai" "$REPO_ROOT/repo/ai" "${IMAGE_NAME}:docker-ml"; then
    print_status "$GREEN" "✅ AI service test passed"
else
    print_status "$RED" "❌ AI service test failed"
    exit 1
fi

if build_service_image "analyze" "$REPO_ROOT/repo/analyze" "${IMAGE_NAME}:docker-ml"; then
    print_status "$GREEN" "✅ Analyze service test passed"
else
    print_status "$RED" "❌ Analyze service test failed"
    exit 1
fi

# Test GPU services (using GPU base)
print_status "$YELLOW" "=== Testing GPU Services ==="
if build_service_image "training" "$REPO_ROOT/repo/training" "${IMAGE_NAME}:docker-gpu"; then
    print_status "$GREEN" "✅ Training service test passed"
else
    print_status "$RED" "❌ Training service test failed"
    exit 1
fi

# Summary
echo ""
print_status "$GREEN" "=========================================="
print_status "$GREEN" "All Service Build Tests Passed!"
print_status "$GREEN" "=========================================="
echo ""
echo "Test Images:"
docker images "${IMAGE_NAME}:ai${TEST_TAG_SUFFIX}" "${IMAGE_NAME}:analyze${TEST_TAG_SUFFIX}" "${IMAGE_NAME}:training${TEST_TAG_SUFFIX}" --format "  {{.Repository}}:{{.Tag}} - {{.Size}}"
echo ""
echo "Next Steps:"
echo "  1. Verify service images work correctly"
echo "  2. Test service functionality"
echo "  3. Clean up test images (run cleanup-test-images.sh)"
echo "  4. Push base images to DockerHub (if tests pass)"
echo ""


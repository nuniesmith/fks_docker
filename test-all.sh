#!/bin/bash
# Complete test suite for Docker base images
# This script builds all base images and tests them with service builds

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "FKS Docker Base Images - Complete Test Suite"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Step 1: Build all base images
print_status "$BLUE" "Step 1: Building all base images..."
if ./build-all-bases.sh; then
    print_status "$GREEN" "✅ All base images built successfully"
else
    print_status "$RED" "❌ Base image build failed"
    exit 1
fi

echo ""
print_status "$BLUE" "Step 2: Testing base images with service builds..."
if ./test-service-builds.sh; then
    print_status "$GREEN" "✅ All service build tests passed"
else
    print_status "$RED" "❌ Service build test failed"
    exit 1
fi

echo ""
print_status "$GREEN" "=========================================="
print_status "$GREEN" "All Tests Passed!"
print_status "$GREEN" "=========================================="
echo ""
echo "Summary:"
echo "  ✅ Base images built successfully"
echo "  ✅ Service images built successfully"
echo "  ✅ All tests passed"
echo ""
echo "Next Steps:"
echo "  1. Review test results"
echo "  2. Clean up test images (run cleanup-test-images.sh)"
echo "  3. Push base images to DockerHub (if ready)"
echo ""


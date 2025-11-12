#!/bin/bash
# Clean up test images after testing

set -e

IMAGE_NAME="nuniesmith/fks"
TEST_TAG_SUFFIX="-test"

echo "=========================================="
echo "Cleaning Up Test Images"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# List test images
print_status "$YELLOW" "Finding test images..."
TEST_IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "${IMAGE_NAME}.*${TEST_TAG_SUFFIX}" || true)

if [ -z "$TEST_IMAGES" ]; then
    print_status "$YELLOW" "No test images found"
    exit 0
fi

echo "Test images found:"
echo "$TEST_IMAGES" | while read -r image; do
    echo "  - $image"
done
echo ""

# Ask for confirmation
read -p "Do you want to remove these test images? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "$YELLOW" "Cleanup cancelled"
    exit 0
fi

# Remove test images
print_status "$YELLOW" "Removing test images..."
echo "$TEST_IMAGES" | while read -r image; do
    if docker rmi "$image" 2>/dev/null; then
        print_status "$GREEN" "✅ Removed: $image"
    else
        print_status "$RED" "❌ Failed to remove: $image"
    fi
done

print_status "$GREEN" "✅ Cleanup complete"


# Build and Verify Script Usage

The `build-and-verify.sh` script builds Docker images, checks their sizes, and verifies everything looks good.

## Quick Start

```bash
cd repo/docker
./build-and-verify.sh
```

This will:
1. Build all base images (CPU, ML, GPU)
2. Build all service images
3. Verify all images can run
4. Show image sizes and summary

## Options

### Build Options

```bash
# Build everything (default)
./build-and-verify.sh

# Build only base images (skip services)
./build-and-verify.sh --no-services

# Build only services (skip base images, assumes they exist)
./build-and-verify.sh --no-base

# Build specific service only
./build-and-verify.sh --service ai

# Build and push to DockerHub
./build-and-verify.sh --push
```

### Verification Options

```bash
# Skip image verification
./build-and-verify.sh --no-verify

# Skip size reporting
./build-and-verify.sh --no-sizes
```

### Combined Examples

```bash
# Build and push everything
./build-and-verify.sh --push

# Build only AI service and verify
./build-and-verify.sh --service ai

# Build services only (use existing base images) and push
./build-and-verify.sh --no-base --push
```

## Output

The script provides:

1. **Build Progress**: Colored output showing build status
2. **Image Sizes**: Detailed size report for all images
3. **Verification**: Tests that images can run
4. **Summary**: Total sizes and build statistics

### Example Output

```
========================================
Image Size Report
========================================

Base Images:
Image                          Size (MB)
-----------------------------------------------
nuniesmith/fks:docker              650.23
nuniesmith/fks:docker-ml          2450.67
nuniesmith/fks:docker-gpu         7850.12

Service Images:
Image                          Size (MB)
-----------------------------------------------
nuniesmith/fks:web-latest         280.45
nuniesmith/fks:api-latest         295.12
...
```

## What Gets Verified

1. **Base Images**:
   - Image exists locally
   - Image size is reported
   - Image can run Python

2. **Service Images**:
   - Image exists locally
   - Image size is reported
   - Image can run (Python or basic commands)

## Troubleshooting

### Base Image Not Found

If you get "base image not found" errors:
```bash
# Build base images first
./build-and-verify.sh --no-services
```

### Service Build Fails

Check:
1. Base image exists: `docker images | grep nuniesmith/fks`
2. Service directory exists: `ls ../<service>`
3. Dockerfile exists: `ls Dockerfile.<service>`

### Size Calculations

If size calculations fail, install `bc`:
```bash
# Ubuntu/Debian
sudo apt-get install bc

# macOS
brew install bc
```

## Comparison with build-all.sh

| Feature | build-all.sh | build-and-verify.sh |
|---------|--------------|---------------------|
| Build images | ✅ | ✅ |
| Push to DockerHub | ✅ | ✅ |
| Image size reporting | Basic | Detailed |
| Image verification | Basic | Comprehensive |
| Size calculations | No | Yes |
| Summary statistics | Basic | Detailed |

Use `build-and-verify.sh` when you want:
- Detailed size information
- Comprehensive verification
- Better visibility into what was built

Use `build-all.sh` when you want:
- Simpler output
- Faster execution (less verification)
- Basic build functionality


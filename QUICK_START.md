# FKS Docker Base Images - Quick Start Guide

This guide provides a quick start for building and testing Docker base images locally.

## Prerequisites

- Docker installed and running
- Docker BuildKit enabled (for faster builds)
- Sufficient disk space (~20GB for all base images)

## Quick Start

### 1. Build All Base Images

```bash
# Bash
cd repo/docker
chmod +x build-all-bases.sh
./build-all-bases.sh

# PowerShell
cd repo/docker
.\build-all-bases.ps1
```

This will build:
- **CPU Base** (`nuniesmith/fks:docker`) - ~3-5 minutes
- **ML Base** (`nuniesmith/fks:docker-ml`) - ~5-10 minutes
- **GPU Base** (`nuniesmith/fks:docker-gpu`) - ~10-15 minutes

**Total build time**: ~18-30 minutes

### 2. Test Base Images with Service Builds

```bash
# Bash
chmod +x test-service-builds.sh
./test-service-builds.sh

# PowerShell
.\test-service-builds.ps1
```

This will test:
- **AI service** (using ML base) - ~1-2 minutes
- **Analyze service** (using ML base) - ~1-2 minutes
- **Training service** (using GPU base) - ~2-3 minutes

**Total test time**: ~4-7 minutes

### 3. Run Complete Test Suite

```bash
# Bash
chmod +x test-all.sh
./test-all.sh

# PowerShell
.\test-all.ps1
```

This runs both build and test steps in sequence.

## Expected Results

### Build Times

- **CPU Base**: ~3-5 minutes
- **ML Base**: ~5-10 minutes
- **GPU Base**: ~10-15 minutes
- **AI Service**: ~1-2 minutes
- **Analyze Service**: ~1-2 minutes
- **Training Service**: ~2-3 minutes

### Image Sizes

- **CPU Base**: ~500-700MB
- **ML Base**: ~2-3GB
- **GPU Base**: ~5-8GB
- **AI Service**: ~2.5-3.5GB
- **Analyze Service**: ~2.5-3.5GB
- **Training Service**: ~6-9GB

## Verification

### Check Base Images

```bash
# List base images
docker images nuniesmith/fks:docker nuniesmith/fks:docker-ml nuniesmith/fks:docker-gpu

# Verify CPU base
docker run --rm nuniesmith/fks:docker python -c "import sys; print(sys.version)"

# Verify ML base
docker run --rm nuniesmith/fks:docker-ml python -c "import langchain; import chromadb; print('✅ ML packages installed')"

# Verify GPU base
docker run --rm nuniesmith/fks:docker-gpu python -c "import torch; print(f'✅ PyTorch {torch.__version__} installed')"
```

### Check Service Images

```bash
# List test images
docker images nuniesmith/fks:ai-test nuniesmith/fks:analyze-test nuniesmith/fks:training-test

# Test AI service
docker run --rm nuniesmith/fks:ai-test python -c "import langchain; print('✅ AI service works')"

# Test Analyze service
docker run --rm nuniesmith/fks:analyze-test python -c "import langchain; print('✅ Analyze service works')"

# Test Training service
docker run --rm nuniesmith/fks:training-test python -c "import torch; print('✅ Training service works')"
```

## Troubleshooting

### Build Fails

1. **Check Docker is running**: `docker info`
2. **Check disk space**: `docker system df`
3. **Check network connectivity**: `ping github.com`
4. **Check build logs**: Look for specific error messages

### Package Import Fails

1. **Check base image**: Verify packages are installed in base image
2. **Check requirements.txt**: Verify packages are not duplicated
3. **Check Python path**: Verify PYTHONPATH is set correctly

### Out of Disk Space

```bash
# Clean up unused images
docker system prune -a

# Remove test images
./cleanup-test-images.sh
```

## Next Steps

After successful local testing:

1. **Review test results**: Verify all tests passed
2. **Check build times**: Compare with expected times
3. **Check image sizes**: Compare with expected sizes
4. **Commit changes**: Commit Dockerfile and requirements.txt changes
5. **Push to GitHub**: Push changes to trigger GitHub Actions
6. **Monitor GitHub Actions**: Verify base images build on GitHub Actions
7. **Push to DockerHub**: Base images will be pushed automatically

## Cleanup

### Remove Test Images

```bash
# Bash
./cleanup-test-images.sh

# PowerShell
.\cleanup-test-images.ps1
```

### Remove All Test Images Manually

```bash
docker rmi nuniesmith/fks:ai-test nuniesmith/fks:analyze-test nuniesmith/fks:training-test
```

## See Also

- [README.md](./README.md) - Complete documentation
- [README_TESTING.md](./README_TESTING.md) - Detailed testing guide
- [DOCKER_BASE_STRATEGY.md](./DOCKER_BASE_STRATEGY.md) - Strategy document
- [BASE_IMAGES_SUMMARY.md](./BASE_IMAGES_SUMMARY.md) - Implementation summary


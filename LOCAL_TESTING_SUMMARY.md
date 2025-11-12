# FKS Docker Base Images - Local Testing Summary

## Overview

This document provides a quick summary of how to build and test Docker base images locally before pushing to DockerHub.

## Quick Start

### 1. Build All Base Images

```powershell
cd repo/docker
.\build-all-bases.ps1
```

This will:
- Build CPU base (`nuniesmith/fks:docker`) - ~3-5 minutes
- Build ML base (`nuniesmith/fks:docker-ml`) - ~5-10 minutes
- Build GPU base (`nuniesmith/fks:docker-gpu`) - ~10-15 minutes
- Verify all base images are working
- Show build times and image sizes

**Total build time**: ~18-30 minutes

### 2. Test Base Images with Service Builds

```powershell
.\test-service-builds.ps1
```

This will:
- Test AI service (using ML base) - ~1-2 minutes
- Test Analyze service (using ML base) - ~1-2 minutes
- Test Training service (using GPU base) - ~2-3 minutes
- Verify all service images are working

**Total test time**: ~4-7 minutes

### 3. Run Complete Test Suite

```powershell
.\test-all.ps1
```

This runs both build and test steps in sequence.

## What Gets Built

### Base Images

1. **CPU Base** (`nuniesmith/fks:docker`)
   - TA-Lib C library (pre-compiled)
   - Build tools (gcc, g++, make, cmake, etc.)
   - Scientific libraries (OpenBLAS, LAPACK)
   - Size: ~500-700MB

2. **ML Base** (`nuniesmith/fks:docker-ml`)
   - CPU Base + LangChain ecosystem
   - ChromaDB (vector store)
   - sentence-transformers (embeddings)
   - Ollama integration
   - Size: ~2-3GB

3. **GPU Base** (`nuniesmith/fks:docker-gpu`)
   - ML Base + PyTorch
   - Transformers
   - Training libraries (wandb, mlflow, tensorboard)
   - Reinforcement learning (stable-baselines3, gymnasium)
   - Size: ~5-8GB

### Test Service Images

1. **AI Service** (`nuniesmith/fks:ai-test`)
   - Uses ML base
   - Contains AI service code
   - Size: ~2.5-3.5GB

2. **Analyze Service** (`nuniesmith/fks:analyze-test`)
   - Uses ML base
   - Contains Analyze service code
   - Size: ~2.5-3.5GB

3. **Training Service** (`nuniesmith/fks:training-test`)
   - Uses GPU base
   - Contains Training service code
   - Size: ~6-9GB

## Verification

### Check Base Images

```powershell
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

```powershell
# List test images
docker images nuniesmith/fks:ai-test nuniesmith/fks:analyze-test nuniesmith/fks:training-test

# Test AI service
docker run --rm nuniesmith/fks:ai-test python -c "import langchain; print('✅ AI service works')"

# Test Analyze service
docker run --rm nuniesmith/fks:analyze-test python -c "import langchain; print('✅ Analyze service works')"

# Test Training service
docker run --rm nuniesmith/fks:training-test python -c "import torch; print('✅ Training service works')"
```

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

```powershell
# Clean up unused images
docker system prune -a

# Remove test images
.\cleanup-test-images.ps1
```

## Cleanup

### Remove Test Images

```powershell
.\cleanup-test-images.ps1
```

### Remove All Test Images Manually

```powershell
docker rmi nuniesmith/fks:ai-test nuniesmith/fks:analyze-test nuniesmith/fks:training-test
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

## Files Created

### Scripts

- `build-all-bases.sh` / `build-all-bases.ps1` - Build all base images
- `test-service-builds.sh` / `test-service-builds.ps1` - Test base images with service builds
- `test-all.sh` / `test-all.ps1` - Run complete test suite
- `cleanup-test-images.sh` / `cleanup-test-images.ps1` - Clean up test images

### Documentation

- `README_TESTING.md` - Detailed testing guide
- `QUICK_START.md` - Quick start guide
- `LOCAL_TESTING_SUMMARY.md` - This summary

## See Also

- [README.md](./README.md) - Complete documentation
- [README_TESTING.md](./README_TESTING.md) - Detailed testing guide
- [QUICK_START.md](./QUICK_START.md) - Quick start guide
- [DOCKER_BASE_STRATEGY.md](./DOCKER_BASE_STRATEGY.md) - Strategy document
- [BASE_IMAGES_SUMMARY.md](./BASE_IMAGES_SUMMARY.md) - Implementation summary


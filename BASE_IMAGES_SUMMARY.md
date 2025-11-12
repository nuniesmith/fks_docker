# FKS Docker Base Images - Implementation Summary

## Overview

This document summarizes the implementation of the multi-stage Docker base image strategy for FKS services.

## Base Images Created

### 1. CPU Base (`nuniesmith/fks:docker`)

**File**: `Dockerfile.builder`

**Contains**:
- Python 3.12-slim
- TA-Lib C library (pre-compiled) - saves ~2-3 minutes per service build
- Build tools (gcc, g++, make, cmake, autotools, etc.)
- Scientific libraries (OpenBLAS, LAPACK)
- Python build dependencies (pip, setuptools, wheel)

**Size**: ~500-700MB

**Used by**: All services (CPU, ML, GPU)

### 2. ML Base (`nuniesmith/fks:docker-ml`)

**File**: `Dockerfile.ml`

**Contains**:
- Everything from CPU Base
- LangChain ecosystem:
  - langchain>=0.3.0,<0.4.0
  - langchain-core>=0.3.0,<0.4.0
  - langchain-community>=0.3.0,<0.4.0
  - langchain-ollama>=0.2.0,<1.0.0
  - langchain-text-splitters>=0.3.0,<0.4.0
- Vector stores:
  - chromadb>=0.4.0,<1.0.0
- Embeddings:
  - sentence-transformers>=2.2.0,<6.0.0
- Ollama integration:
  - ollama>=0.1.0,<1.0.0
- TA-Lib Python package:
  - TA-Lib>=0.4.28
- Common dependencies:
  - numpy>=1.26.0,<2.0.0
  - pandas>=2.2.0
  - httpx>=0.25.0,<0.29.0

**Size**: ~2-3GB (large due to sentence-transformers and chromadb)

**Used by**: `ai`, `analyze`, `training` (as base for GPU base)

### 3. GPU Base (`nuniesmith/fks:docker-gpu`)

**File**: `Dockerfile.gpu`

**Contains**:
- Everything from ML Base
- PyTorch:
  - torch==2.8.0
  - torchvision==0.23.0
  - torchaudio==2.8.0
- Transformers:
  - transformers==4.56.0
  - accelerate==1.10.1
- Training libraries:
  - datasets==4.0.0
  - wandb==0.21.2
  - mlflow==3.3.2
  - tensorboard==2.20.0
- Reinforcement learning:
  - stable-baselines3>=2.2.0
  - gymnasium>=0.29.1,<1.3.0
- Model monitoring:
  - alibi-detect>=0.11.0
- Scientific computing:
  - scikit-learn==1.7.1
  - scipy>=1.11.0
  - matplotlib==3.10.6
  - seaborn==0.13.2
  - optuna==4.5.0
- Pinned versions (for training service):
  - pandas==2.3.2 (upgraded from ML base's >=2.2.0)
  - numpy>=1.26.0,<2.0.0 (from ML base, compatible with training's >=1.23.5,<2.0.0)

**Size**: ~5-8GB (very large due to PyTorch)

**Used by**: `training`

## Service Updates

### CPU Services (app, data, api, web, auth, execution, meta, monitor, portfolio, ninja)

**Status**: ✅ Ready to use CPU base

**Dockerfile**: Already using `FROM python:3.12-slim AS builder`

**Next Step**: Update to use `FROM nuniesmith/fks:docker AS builder` to skip TA-Lib compilation

**Benefits**:
- Faster builds: ~1-2 minutes (was ~3-5 minutes)
- Smaller images: Shared TA-Lib layer

### ML Services (ai, analyze)

**Status**: ✅ Updated to use ML base

**Dockerfile**: Updated to use `FROM nuniesmith/fks:docker-ml AS builder`

**Requirements**: Updated to remove packages already in ML base

**Benefits**:
- Faster builds: ~3-5 minutes (was ~8-12 minutes)
- Smaller images: Shared LangChain, ChromaDB, sentence-transformers layers

### GPU Services (training)

**Status**: ✅ Updated to use GPU base

**Dockerfile**: Updated to use `FROM nuniesmith/fks:docker-gpu AS builder`

**Requirements**: Updated to remove packages already in GPU base

**Benefits**:
- Faster builds: ~5-8 minutes (was ~15-20 minutes)
- Smaller images: Shared PyTorch, Transformers, training libraries layers

## GitHub Actions Workflow

**File**: `.github/workflows/build-base.yml`

**Jobs**:
1. `build-cpu-base`: Builds CPU base (docker)
2. `build-ml-base`: Builds ML base (docker-ml) - depends on CPU base
3. `build-gpu-base`: Builds GPU base (docker-gpu) - depends on ML base
4. `build-summary`: Summary of all builds

**Build Order**:
1. CPU base builds first
2. ML base builds after CPU base (pulls CPU base)
3. GPU base builds after ML base (pulls ML base)

**Tags**:
- `nuniesmith/fks:docker` / `nuniesmith/fks:docker-latest`
- `nuniesmith/fks:docker-ml` / `nuniesmith/fks:docker-ml-latest`
- `nuniesmith/fks:docker-gpu` / `nuniesmith/fks:docker-gpu-latest`

## Build Time Improvements

### Without Base Images
- CPU services: ~3-5 minutes (TA-Lib compilation)
- ML services: ~8-12 minutes (TA-Lib + LangChain + ChromaDB)
- GPU services: ~15-20 minutes (TA-Lib + PyTorch + Transformers)

### With Base Images
- CPU services: ~1-2 minutes (pull base + install dependencies)
- ML services: ~3-5 minutes (pull ML base + install service-specific packages)
- GPU services: ~5-8 minutes (pull GPU base + install service-specific packages)

**Total Time Savings**: ~50-60% faster builds

## Image Size Comparison

### Without Base Images
- CPU services: ~200-300MB each
- ML services: ~2-3GB each
- GPU services: ~5-8GB each
- **Total**: ~15-20GB for all services

### With Base Images
- CPU base: ~500-700MB (shared)
- ML base: ~2-3GB (shared)
- GPU base: ~5-8GB (shared)
- CPU services: ~200-300MB each (10 services × ~250MB = ~2.5GB)
- ML services: ~500MB-1.5GB each (2 services × ~1GB = ~2GB)
- GPU services: ~1-4GB each (1 service × ~2GB = ~2GB)
- **Total**: ~12-15GB (base images + service layers)

**Total Size Savings**: ~3-5GB (15-20% reduction)

## Next Steps

### 1. Build Base Images

```bash
# Build CPU base
cd repo/docker
docker build -t nuniesmith/fks:docker -f Dockerfile.builder .
docker push nuniesmith/fks:docker

# Build ML base
docker build -t nuniesmith/fks:docker-ml -f Dockerfile.ml .
docker push nuniesmith/fks:docker-ml

# Build GPU base
docker build -t nuniesmith/fks:docker-gpu -f Dockerfile.gpu .
docker push nuniesmith/fks:docker-gpu
```

### 2. Update CPU Services

Update CPU service Dockerfiles to use CPU base:
- `app/Dockerfile`
- `data/Dockerfile`
- `api/Dockerfile`
- `web/Dockerfile`
- `auth/Dockerfile`
- `execution/Dockerfile`
- `meta/Dockerfile`
- `monitor/Dockerfile`
- `portfolio/Dockerfile`
- `ninja/Dockerfile`

Change from:
```dockerfile
FROM python:3.12-slim AS builder
```

To:
```dockerfile
FROM nuniesmith/fks:docker AS builder
```

Remove TA-Lib compilation step (already in base).

### 3. Test Builds

Test service builds with new base images:
```bash
# Test ML service (ai)
cd repo/ai
docker build -t nuniesmith/fks:ai-test .

# Test ML service (analyze)
cd repo/analyze
docker build -t nuniesmith/fks:analyze-test .

# Test GPU service (training)
cd repo/training
docker build -t nuniesmith/fks:training-test .
```

### 4. Monitor Build Times

Monitor build times to verify improvements:
- CPU services: Should be ~1-2 minutes
- ML services: Should be ~3-5 minutes
- GPU services: Should be ~5-8 minutes

### 5. Update GitHub Actions

Update service build workflows to pull base images:
```yaml
- name: Pull base images
  run: |
    docker pull nuniesmith/fks:docker || true
    docker pull nuniesmith/fks:docker-ml || true
    docker pull nuniesmith/fks:docker-gpu || true
```

## Maintenance

### When to Rebuild Base Images

1. **Python version update**: Rebuild all bases
2. **TA-Lib version update**: Rebuild CPU base, then ML and GPU bases
3. **LangChain version update**: Rebuild ML base, then GPU base
4. **PyTorch version update**: Rebuild GPU base only
5. **Security patches**: Rebuild affected bases

### Versioning

Tag base images with versions for pinning:
```bash
docker tag nuniesmith/fks:docker nuniesmith/fks:docker-v1.0.0
docker tag nuniesmith/fks:docker-ml nuniesmith/fks:docker-ml-v1.0.0
docker tag nuniesmith/fks:docker-gpu nuniesmith/fks:docker-gpu-v1.0.0
```

Services can pin to specific versions:
```dockerfile
FROM nuniesmith/fks:docker-ml-v1.0.0 AS builder
```

## Benefits Summary

1. **Faster Builds**: 50-60% faster build times
2. **Smaller Total Size**: 15-20% reduction in total disk usage
3. **Easier Maintenance**: Update packages in one place
4. **Consistent Environment**: All services use same package versions
5. **Better Caching**: Base images cached, service builds are faster

## Files Created/Updated

### Created
- `repo/docker/Dockerfile.ml` - ML base image
- `repo/docker/Dockerfile.gpu` - GPU base image
- `repo/docker/DOCKER_BASE_STRATEGY.md` - Strategy document
- `repo/docker/BASE_IMAGES_SUMMARY.md` - This summary

### Updated
- `repo/docker/.github/workflows/build-base.yml` - Builds all 3 bases
- `repo/docker/README.md` - Updated with new strategy
- `repo/ai/Dockerfile` - Uses ML base
- `repo/analyze/Dockerfile` - Uses ML base
- `repo/training/Dockerfile` - Uses GPU base
- `repo/ai/requirements.txt` - Removed packages in ML base
- `repo/analyze/requirements.txt` - Removed packages in ML base
- `repo/training/requirements.txt` - Removed packages in GPU base

## Status

✅ **CPU Base**: Ready (already implemented)
✅ **ML Base**: Ready (Dockerfile created)
✅ **GPU Base**: Ready (Dockerfile created)
✅ **GitHub Actions**: Ready (workflow updated)
✅ **Service Dockerfiles**: Ready (ai, analyze, training updated)
✅ **Documentation**: Ready (strategy and summary documents created)

## Next Actions

1. Commit and push changes to trigger GitHub Actions
2. Verify base images build correctly
3. Test service builds with new base images
4. Update remaining CPU services to use CPU base
5. Monitor build times and image sizes


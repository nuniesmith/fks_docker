# FKS Docker Base Image Strategy

## Overview

This document outlines the multi-stage base image strategy for FKS services to optimize build times, reduce image sizes, and minimize duplication.

## Base Image Hierarchy

```
CPU Base (docker)           → Lightweight: TA-Lib + build tools
  ├─ ML Base (docker-ml)    → CPU Base + LangChain, ChromaDB, sentence-transformers
  │   └─ GPU Base (docker-gpu) → ML Base + PyTorch, Transformers, Accelerate
  └─ Direct use by CPU services (app, data, api, web, etc.)
```

## Base Images

### 1. CPU Base (`nuniesmith/fks:docker`)

**Purpose**: Foundation for all services with TA-Lib and build tools

**Contains**:
- Python 3.12-slim
- TA-Lib C library (pre-compiled)
- Build tools (gcc, g++, make, cmake, autotools, etc.)
- Scientific libraries (OpenBLAS, LAPACK)
- Python build dependencies (pip, setuptools, wheel)

**Used by**:
- CPU services: `app`, `data`, `api`, `web`, `auth`, `execution`, `meta`, `monitor`, `portfolio`, `ninja`
- ML services: `ai`, `analyze` (as base for ML base)
- GPU services: `training` (as base for GPU base)

**Size**: ~500-700MB

### 2. ML Base (`nuniesmith/fks:docker-ml`)

**Purpose**: Pre-built ML/AI packages for LangChain-based services

**Contains**:
- Everything from CPU Base
- LangChain ecosystem (langchain, langchain-core, langchain-community, langchain-ollama)
- Vector stores (chromadb)
- Embeddings (sentence-transformers)
- Ollama integration
- TA-Lib Python package

**Used by**:
- `ai` service (LangChain multi-agent system)
- `analyze` service (RAG system for project improvements)
- `training` service (as base for GPU base, if using LangChain)

**Size**: ~2-3GB (large due to sentence-transformers and chromadb)

### 3. GPU Base (`nuniesmith/fks:docker-gpu`)

**Purpose**: Pre-built PyTorch and transformers for GPU training

**Contains**:
- Everything from ML Base (or CPU Base, depending on strategy)
- PyTorch (torch, torchvision, torchaudio)
- Transformers (transformers, accelerate)
- Training libraries (datasets, wandb, mlflow)
- Reinforcement learning (stable-baselines3, gymnasium)
- Model monitoring (alibi-detect)

**Used by**:
- `training` service (GPU batch training)

**Size**: ~5-8GB (very large due to PyTorch)

## Strategy Options

### Option 1: Separate ML and GPU Bases (Recommended)

**Pros**:
- Smaller ML base (2-3GB) for `ai` and `analyze`
- GPU base only includes PyTorch when needed
- Faster builds for ML services (don't need PyTorch)

**Cons**:
- Two separate base images to maintain
- Training service needs GPU base (larger)

**Structure**:
```
CPU Base (docker)
  ├─ ML Base (docker-ml) → ai, analyze
  └─ GPU Base (docker-gpu) → training (includes ML packages if needed)
```

### Option 2: Single GPU Base with ML Packages

**Pros**:
- Single base image for all ML/GPU services
- Simpler maintenance
- All services use same ML packages

**Cons**:
- Larger base image (5-8GB) for all services
- Slower builds for ML services (pull larger image)
- Wastes space for services that don't need PyTorch

**Structure**:
```
CPU Base (docker)
  └─ GPU Base (docker-gpu) → ai, analyze, training (all use GPU base)
```

### Option 3: Separate GPU Base without ML Packages

**Pros**:
- Smallest GPU base (only PyTorch, no LangChain)
- Fastest builds for training service

**Cons**:
- Training service can't use LangChain if needed
- ML services need separate ML base

**Structure**:
```
CPU Base (docker)
  ├─ ML Base (docker-ml) → ai, analyze
  └─ GPU Base (docker-gpu) → training (PyTorch only, no LangChain)
```

## Recommended Strategy: Option 1

**Reasoning**:
- `ai` and `analyze` don't need PyTorch (save ~3-5GB per service)
- `training` can use ML base if it needs LangChain, or GPU base directly if not
- Faster builds for ML services (smaller base image)
- More flexible (services can choose what they need)

## Implementation

### 1. CPU Base (`Dockerfile.builder`)

Already implemented in `repo/docker/Dockerfile.builder`

### 2. ML Base (`Dockerfile.ml`)

Create `repo/docker/Dockerfile.ml`:
```dockerfile
FROM nuniesmith/fks:docker AS ml-base

# Install ML/AI packages
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir \
    langchain>=0.3.0 \
    langchain-core>=0.3.0 \
    langchain-community>=0.3.0 \
    langchain-ollama>=0.2.0 \
    chromadb>=0.5.0 \
    sentence-transformers>=3.0.0 \
    ollama>=0.3.0 \
    TA-Lib>=0.4.28
```

### 3. GPU Base (`Dockerfile.gpu`)

Create `repo/docker/Dockerfile.gpu`:
```dockerfile
FROM nuniesmith/fks:docker-ml AS gpu-base

# Install PyTorch and transformers
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir \
    torch==2.8.0 \
    torchvision==0.23.0 \
    torchaudio==2.8.0 \
    transformers==4.56.0 \
    accelerate==1.10.1 \
    datasets==4.0.0 \
    wandb==0.21.2 \
    stable-baselines3>=2.2.0 \
    gymnasium>=0.29.1
```

## Service Dockerfiles

### CPU Services (app, data, api, web, etc.)

```dockerfile
FROM nuniesmith/fks:docker AS builder

WORKDIR /app
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --user --no-cache-dir -r requirements.txt

FROM python:3.12-slim
# ... runtime stage
```

### ML Services (ai, analyze)

```dockerfile
FROM nuniesmith/fks:docker-ml AS builder

WORKDIR /app
COPY requirements.txt ./
# ML packages already installed, just install service-specific packages
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --user --no-cache-dir -r requirements.txt

FROM python:3.12-slim
# ... runtime stage
```

### GPU Services (training)

```dockerfile
FROM nuniesmith/fks:docker-gpu AS builder

WORKDIR /app
COPY requirements.txt ./
# PyTorch and ML packages already installed
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --user --no-cache-dir -r requirements.txt

FROM python:3.12-slim
# ... runtime stage
```

## Build Times

### Without Base Images
- CPU services: ~3-5 minutes (TA-Lib compilation)
- ML services: ~8-12 minutes (TA-Lib + LangChain + ChromaDB)
- GPU services: ~15-20 minutes (TA-Lib + PyTorch + Transformers)

### With Base Images
- CPU services: ~1-2 minutes (pull base + install dependencies)
- ML services: ~3-5 minutes (pull ML base + install service-specific packages)
- GPU services: ~5-8 minutes (pull GPU base + install service-specific packages)

## Image Sizes

### Without Base Images
- CPU services: ~200-300MB
- ML services: ~2-3GB
- GPU services: ~5-8GB

### With Base Images
- CPU services: ~200-300MB (same, base is shared)
- ML services: ~2.5-3.5GB (base ~2GB + service ~500MB-1.5GB)
- GPU services: ~6-9GB (base ~5GB + service ~1-4GB)

**Note**: While individual service images are slightly larger, total disk usage is reduced because base images are shared across services.

## GitHub Actions Workflow

Update `.github/workflows/build-base.yml` to build all base images:

```yaml
jobs:
  build-cpu-base:
    # Build CPU base (docker)
  
  build-ml-base:
    needs: build-cpu-base
    # Build ML base (docker-ml)
  
  build-gpu-base:
    needs: build-ml-base
    # Build GPU base (docker-gpu)
```

## Maintenance

### When to Rebuild Base Images

1. **Python version update**: Rebuild all bases
2. **TA-Lib version update**: Rebuild CPU base, then ML and GPU bases
3. **LangChain version update**: Rebuild ML base, then GPU base
4. **PyTorch version update**: Rebuild GPU base only
5. **Security patches**: Rebuild affected bases

### Versioning

Tag base images with versions:
- `nuniesmith/fks:docker-v1.0.0`
- `nuniesmith/fks:docker-ml-v1.0.0`
- `nuniesmith/fks:docker-gpu-v1.0.0`

Services can pin to specific versions:
```dockerfile
FROM nuniesmith/fks:docker-ml-v1.0.0 AS builder
```

## Benefits

1. **Faster Builds**: TA-Lib, LangChain, PyTorch compiled once, not per service
2. **Smaller Total Size**: Shared layers reduce total disk usage
3. **Easier Maintenance**: Update packages in one place
4. **Consistent Environment**: All services use same package versions
5. **Better Caching**: Base images cached, service builds are faster

## Next Steps

1. ✅ Create CPU base (`Dockerfile.builder`) - DONE
2. ⏳ Create ML base (`Dockerfile.ml`) - IN PROGRESS
3. ⏳ Create GPU base (`Dockerfile.gpu`) - PENDING
4. ⏳ Update service Dockerfiles to use base images - PENDING
5. ⏳ Update GitHub Actions to build all base images - PENDING
6. ⏳ Test builds and measure improvements - PENDING


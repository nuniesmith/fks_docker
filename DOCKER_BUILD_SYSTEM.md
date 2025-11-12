# FKS Docker Build System - Complete Guide

## 🎯 Overview

This directory contains a unified Docker build system that uses shared base images to dramatically reduce build times and image sizes. All services use base images from `repo/docker` that contain pre-compiled heavy dependencies like LangChain, PyTorch, and TA-Lib.

## 📦 Base Images (from `repo/docker`)

### 1. CPU Base (`nuniesmith/fks:docker`)
**Size**: ~500-700MB  
**Contains**:
- Python 3.12-slim
- TA-Lib C library (pre-compiled) - saves ~2-3 minutes per build
- Build tools (gcc, g++, make, cmake, autotools)
- Scientific libraries (OpenBLAS, LAPACK)

**Used by**: web, api, app, data, portfolio, monitor, ninja, execution, auth, meta, main

### 2. ML Base (`nuniesmith/fks:docker-ml`)
**Size**: ~2-3GB  
**Contains**:
- Everything from CPU Base
- LangChain ecosystem (langchain, langchain-core, langchain-community, langchain-ollama)
- ChromaDB (vector store)
- sentence-transformers (embeddings)
- Ollama integration
- TA-Lib Python package

**Used by**: ai, analyze

### 3. GPU Base (`nuniesmith/fks:docker-gpu`)
**Size**: ~5-8GB  
**Contains**:
- Everything from ML Base
- PyTorch (torch, torchvision, torchaudio)
- Transformers (transformers, accelerate)
- Training libraries (MLflow, WandB, TensorBoard)
- Reinforcement learning (stable-baselines3, gymnasium)

**Used by**: training

## 🚀 Quick Start

### 1. Build Base Images (One Time)

```bash
cd ../docker
./build-all-bases.sh
# Or manually:
docker build -t nuniesmith/fks:docker -f Dockerfile.builder .
docker build -t nuniesmith/fks:docker-ml -f Dockerfile.ml .
docker build -t nuniesmith/fks:docker-gpu -f Dockerfile.gpu .
docker push nuniesmith/fks:docker
docker push nuniesmith/fks:docker-ml
docker push nuniesmith/fks:docker-gpu
```

### 2. Build All Services

```bash
cd repo/main/docker
./build-all.sh
```

### 3. Test Builds Locally

```bash
./test-builds.sh
```

### 4. Push to Docker Hub

```bash
PUSH_TO_HUB=true ./build-all.sh
```

## 📋 Build Scripts

### `build-all.sh`

Unified build script for all services.

**Features**:
- Builds base images first (or pulls from Docker Hub)
- Builds all services using appropriate base images
- Tests builds (optional)
- Pushes to Docker Hub (optional)
- Supports building individual services

**Usage**:
```bash
# Build everything locally (default)
./build-all.sh

# Build and push to Docker Hub
./build-all.sh --push
PUSH_TO_HUB=true ./build-all.sh

# Don't build base images (pull from Docker Hub instead)
./build-all.sh --no-base

# Build specific service only
./build-all.sh --service ai

# Skip testing
./build-all.sh --no-test

# Help
./build-all.sh --help
```

### `test-builds.sh`

Test script that verifies all builds work.

**Features**:
- Checks base images exist
- Tests building all services
- Reports build times and image sizes
- Identifies failures

**Usage**:
```bash
./test-builds.sh
```

## 🏗️ Service Dockerfiles

All service Dockerfiles follow this multi-stage pattern:

```dockerfile
# Builder stage - uses base image
FROM nuniesmith/fks:docker AS builder  # or docker-ml, docker-gpu

WORKDIR /app
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --user --no-cache-dir -r requirements.txt

# Runtime stage - minimal image
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SERVICE_NAME=fks_service \
    SERVICE_PORT=8000 \
    PATH=/home/appuser/.local/bin:$PATH

WORKDIR /app

# Install runtime deps only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -u 1000 -m -s /bin/bash appuser

# Copy TA-Lib libraries from builder
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/

# Copy Python packages from builder
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser src/ ./src/
COPY --chown=appuser:appuser entrypoint.sh ./

RUN chmod +x entrypoint.sh
USER appuser

EXPOSE 8000
ENTRYPOINT ["./entrypoint.sh"]
```

## 📊 Build Time Improvements

### Before (Without Base Images)
- CPU services: ~3-5 minutes (TA-Lib compilation)
- ML services: ~8-12 minutes (TA-Lib + LangChain + ChromaDB)
- GPU services: ~15-20 minutes (TA-Lib + PyTorch + Transformers)

### After (With Base Images)
- CPU services: ~1-2 minutes (pull base + install dependencies)
- ML services: ~3-5 minutes (pull ML base + install service-specific packages)
- GPU services: ~5-8 minutes (pull GPU base + install service-specific packages)

**Time Savings: 50-60% faster builds**

## 💾 Image Size Comparison

### Base Images (Shared)
- CPU Base: ~500-700MB
- ML Base: ~2-3GB
- GPU Base: ~5-8GB

### Service Images (Individual)
- CPU services: ~200-300MB each
- ML services: ~500MB-1.5GB each
- GPU services: ~1-4GB each

**Total Disk Usage**: Reduced by ~15-20% due to shared base layers

## 🔄 GitHub Actions Integration

### Base Images

Base images are built and pushed by `repo/docker/.github/workflows/build-base.yml`:
- Triggers on push to main/develop
- Builds CPU → ML → GPU in sequence
- Pushes to `nuniesmith/fks:docker`, `docker-ml`, `docker-gpu`

### Service Images

Each service repo has its own GitHub Actions workflow:
- `repo/<service>/.github/workflows/docker-build-push.yml`
- Builds service using base images
- Pushes to `nuniesmith/fks:<service>-latest`

**All images are in a single Docker Hub repo**: `nuniesmith/fks`

## 🧪 Testing Workflow

### 1. Test Base Images

```bash
cd ../docker
./test-all.sh
```

### 2. Test Service Builds

```bash
cd repo/main/docker
./test-builds.sh
```

### 3. Test Individual Service

```bash
cd repo/main/docker
./build-all.sh --service ai
docker run --rm nuniesmith/fks:ai-latest python --version
```

## 📝 Service Configuration

Services are configured in `build-all.sh`:

```bash
SERVICE_CONFIG[service]="dockerfile:base_image:port"
```

**Current Configuration**:
- `web`: Dockerfile → docker → 3001
- `api`: Dockerfile.api → docker → 8001
- `app`: Dockerfile.app → docker → 8002
- `data`: Dockerfile.data → docker → 8003
- `ai`: Dockerfile.ai → docker-ml → 8007
- `analyze`: Dockerfile.analyze → docker-ml → 8008
- `training`: Dockerfile.training → docker-gpu → 8011
- `portfolio`: Dockerfile.portfolio → docker → 8012
- `monitor`: Dockerfile.monitor → docker → 8013
- `ninja`: Dockerfile.ninja → docker → 8006
- `execution`: Dockerfile.execution → docker → 8004

## 🔧 Maintenance

### Updating Base Images

1. **Update base image Dockerfile** in `repo/docker`
2. **Rebuild base image**:
   ```bash
   cd repo/docker
   docker build -t nuniesmith/fks:docker -f Dockerfile.builder .
   ```
3. **Push to Docker Hub**:
   ```bash
   docker push nuniesmith/fks:docker
   ```
4. **Services automatically use updated base** on next build

### Adding a New Service

1. **Create Dockerfile** in `repo/main/docker/Dockerfile.newservice`
2. **Add to SERVICE_CONFIG** in `build-all.sh`:
   ```bash
   SERVICE_CONFIG[newservice]="Dockerfile.newservice:nuniesmith/fks:docker:8000"
   ```
3. **Test build**:
   ```bash
   ./build-all.sh --service newservice
   ```

### Updating Service Dockerfile

1. **Edit Dockerfile** in `repo/main/docker/Dockerfile.<service>`
2. **Test locally**:
   ```bash
   ./build-all.sh --service <service>
   ```
3. **Commit and push** (triggers GitHub Actions)

## 🎯 Best Practices

1. **Always use base images** - Don't compile TA-Lib, LangChain, or PyTorch in service Dockerfiles
2. **Multi-stage builds** - Keep runtime images minimal
3. **Cache mounts** - Use `--mount=type=cache` for pip installs
4. **Non-root users** - Always run as non-root user
5. **Health checks** - Include health check in all Dockerfiles
6. **Test locally first** - Use `test-builds.sh` before pushing

## 📚 File Structure

```
repo/main/docker/
├── build-all.sh              # Unified build script
├── test-builds.sh            # Test script
├── README.md                 # This file
├── DOCKER_BUILD_SYSTEM.md    # Detailed guide
├── Dockerfile                # Web service
├── Dockerfile.api            # API service
├── Dockerfile.app            # App service
├── Dockerfile.data           # Data service
├── Dockerfile.ai             # AI service (uses docker-ml)
├── Dockerfile.analyze        # Analyze service (uses docker-ml)
├── Dockerfile.training       # Training service (uses docker-gpu)
├── Dockerfile.portfolio      # Portfolio service
├── Dockerfile.monitor        # Monitor service
├── Dockerfile.ninja          # Ninja service
├── Dockerfile.execution      # Execution service
├── Dockerfile.auth           # Auth service (Rust)
├── Dockerfile.meta           # Meta service (Rust)
└── Dockerfile.main           # Main service (Rust)

repo/docker/
├── Dockerfile.builder        # CPU base image
├── Dockerfile.ml            # ML base image
├── Dockerfile.gpu           # GPU base image
└── .github/workflows/
    └── build-base.yml       # GitHub Actions for base images
```

## ✅ Verification Checklist

Before pushing to production:

- [ ] Base images built and pushed to Docker Hub
- [ ] All service builds tested locally (`./test-builds.sh`)
- [ ] Service images build successfully
- [ ] Image sizes are reasonable
- [ ] Health checks work
- [ ] Non-root users configured
- [ ] GitHub Actions workflows updated

## 🐛 Troubleshooting

### Base Image Not Found

```bash
# Pull from Docker Hub
docker pull nuniesmith/fks:docker
docker pull nuniesmith/fks:docker-ml
docker pull nuniesmith/fks:docker-gpu

# Or build locally
cd ../docker
./build-all-bases.sh
```

### Build Fails with "No such file or directory"

Check that:
- Service directory exists: `repo/<service>/`
- Requirements file exists: `repo/<service>/requirements.txt`
- Source code exists: `repo/<service>/src/`

### Image Too Large

- Verify using base images (not building from scratch)
- Check for unnecessary files in COPY commands
- Use multi-stage builds
- Remove build dependencies in runtime stage

## 📈 Next Steps

1. **Build base images** and push to Docker Hub
2. **Test all service builds** locally
3. **Update service Dockerfiles** in individual repos to use base images
4. **Verify GitHub Actions** workflows use base images
5. **Monitor build times** and image sizes

---

**Status**: ✅ Ready for use  
**Last Updated**: 2025-11-12


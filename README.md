# FKS Docker Build System

This directory contains Dockerfiles and build scripts for all FKS services, using shared base images to reduce build times and image sizes.

## 🎯 Strategy

### Base Images (from `repo/docker`)

1. **CPU Base** (`nuniesmith/fks:docker`)
   - TA-Lib C library (pre-compiled)
   - Build tools (gcc, g++, make, cmake, etc.)
   - Python 3.12-slim
   - Used by: web, api, app, data, portfolio, monitor, ninja, execution

2. **ML Base** (`nuniesmith/fks:docker-ml`)
   - Everything from CPU Base
   - LangChain ecosystem
   - ChromaDB
   - sentence-transformers
   - Ollama
   - Used by: ai, analyze

3. **GPU Base** (`nuniesmith/fks:docker-gpu`)
   - Everything from ML Base
   - PyTorch, Transformers
   - Training libraries (MLflow, WandB, etc.)
   - Used by: training

### Service Dockerfiles

All service Dockerfiles use multi-stage builds:
- **Builder stage**: Uses base image, installs service-specific packages
- **Runtime stage**: Minimal Python slim image, copies only what's needed

## 🚀 Quick Start

### 1. Build Base Images First

```bash
cd ../docker
./build-all-bases.sh
# Or manually:
docker build -t nuniesmith/fks:docker -f Dockerfile.builder .
docker build -t nuniesmith/fks:docker-ml -f Dockerfile.ml .
docker build -t nuniesmith/fks:docker-gpu -f Dockerfile.gpu .
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

Unified build script that:
- Builds base images (or pulls from Docker Hub)
- Builds all services using base images
- Tests builds (optional)
- Pushes to Docker Hub (optional)

**Usage:**
```bash
# Build everything locally
./build-all.sh

# Build and push to Docker Hub
./build-all.sh --push

# Build without building base images (pull from Docker Hub)
./build-all.sh --no-base

# Build specific service
./build-all.sh --service ai

# Skip testing
./build-all.sh --no-test
```

### `test-builds.sh`

Test script that:
- Verifies base images exist
- Tests building all services
- Reports build times and image sizes
- Identifies any build failures

**Usage:**
```bash
./test-builds.sh
```

## 🏗️ Service Dockerfiles

All Dockerfiles follow this pattern:

```dockerfile
# Builder stage - uses base image
FROM nuniesmith/fks:docker AS builder  # or docker-ml, docker-gpu

WORKDIR /app
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --user --no-cache-dir -r requirements.txt

# Runtime stage - minimal image
FROM python:3.12-slim

# Copy TA-Lib libraries
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/

# Copy Python packages
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser src/ ./src/
```

## 📊 Build Time Improvements

### Without Base Images
- CPU services: ~3-5 minutes (TA-Lib compilation)
- ML services: ~8-12 minutes (TA-Lib + LangChain + ChromaDB)
- GPU services: ~15-20 minutes (TA-Lib + PyTorch + Transformers)

### With Base Images
- CPU services: ~1-2 minutes (pull base + install dependencies)
- ML services: ~3-5 minutes (pull ML base + install service-specific packages)
- GPU services: ~5-8 minutes (pull GPU base + install service-specific packages)

**Time Savings: 50-60% faster builds**

## 💾 Image Size Comparison

### Base Images
- CPU Base: ~500-700MB
- ML Base: ~2-3GB
- GPU Base: ~5-8GB

### Service Images (with base images)
- CPU services: ~200-300MB each
- ML services: ~500MB-1.5GB each
- GPU services: ~1-4GB each

**Total Size**: Base images are shared, so total disk usage is reduced by ~15-20%

## 🔄 GitHub Actions Integration

Each service repo has a GitHub Actions workflow that:
1. Builds the service Docker image
2. Pushes to Docker Hub: `nuniesmith/fks:<service>-latest`

Base images are built separately in `repo/docker` and pushed to:
- `nuniesmith/fks:docker`
- `nuniesmith/fks:docker-ml`
- `nuniesmith/fks:docker-gpu`

## 🧪 Testing

### Local Testing

```bash
# Test all builds
./test-builds.sh

# Test specific service
docker build -f Dockerfile.ai -t nuniesmith/fks:ai-test ../ai/
docker run --rm nuniesmith/fks:ai-test python --version
```

### Build Verification

```bash
# Check base images
docker images | grep nuniesmith/fks | grep -E "(docker|docker-ml|docker-gpu)"

# Check service images
docker images | grep nuniesmith/fks | grep -v docker
```

## 📝 Service Configuration

Services are configured in `build-all.sh`:

```bash
SERVICE_CONFIG[service]="dockerfile:base_image:port"
```

- `dockerfile`: Dockerfile name in this directory
- `base_image`: Base image to use (docker, docker-ml, docker-gpu)
- `port`: Service port

## 🔧 Maintenance

### Updating Base Images

1. Update base image Dockerfile in `repo/docker`
2. Rebuild base image: `cd repo/docker && docker build -t nuniesmith/fks:docker -f Dockerfile.builder .`
3. Push to Docker Hub: `docker push nuniesmith/fks:docker`
4. Services will use updated base on next build

### Adding a New Service

1. Create Dockerfile in this directory (e.g., `Dockerfile.newservice`)
2. Add to `SERVICE_CONFIG` in `build-all.sh`
3. Test build: `./build-all.sh --service newservice`

## 📚 Related Documentation

- Base Images: `../docker/README.md`
- Base Strategy: `../docker/DOCKER_BASE_STRATEGY.md`
- Service Builds: Individual service READMEs

---

**Status**: ✅ Ready for use  
**Last Updated**: 2025-11-12


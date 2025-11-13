# FKS Docker Build and Push Guide

This guide explains how to build and push Docker images for all FKS microservices using shared base images to reduce duplication and build times.

## Overview

The FKS project uses a multi-stage base image strategy:

1. **CPU Base** (`nuniesmith/fks:docker`) - TA-Lib, build tools, Python 3.12
2. **ML Base** (`nuniesmith/fks:docker-ml`) - CPU Base + LangChain, ChromaDB, sentence-transformers
3. **GPU Base** (`nuniesmith/fks:docker-gpu`) - ML Base + PyTorch, Transformers, training libraries

All service images are built from these base images, reducing:
- Build time by 50-60%
- Total disk usage by 15-20%
- Duplication across services

## Quick Start

### 1. Build Base Images First

Base images must be built and pushed to DockerHub before building service images:

```bash
cd repo/docker

# Build all base images
./build-all-bases.sh

# Or build individually
docker build -t nuniesmith/fks:docker -f Dockerfile.builder .
docker build -t nuniesmith/fks:docker-ml -f Dockerfile.ml .
docker build -t nuniesmith/fks:docker-gpu -f Dockerfile.gpu .

# Push to DockerHub
docker push nuniesmith/fks:docker
docker push nuniesmith/fks:docker-ml
docker push nuniesmith/fks:docker-gpu
```

### 2. Build Service Images

Once base images are available on DockerHub, build service images:

```bash
cd repo/docker

# Build all services
PUSH_TO_HUB=true ./build-all.sh

# Build specific service
./build-all.sh --service ai

# Build without pushing
./build-all.sh
```

## GitHub Actions

### Base Images Workflow

The base images are built automatically via `.github/workflows/build-base.yml`:
- Triggers on push to main/develop
- Builds CPU → ML → GPU in sequence
- Pushes to DockerHub: `nuniesmith/fks:docker`, `nuniesmith/fks:docker-ml`, `nuniesmith/fks:docker-gpu`

### Service Images Workflow

Service images can be built via `.github/workflows/build-services.yml`:
- Manual trigger via workflow_dispatch (can select specific service)
- Scheduled daily at 2 AM UTC
- Uses existing base images from DockerHub
- Builds and pushes all service images

## Service Configuration

Services are configured in `build-all.sh`:

```bash
SERVICE_CONFIG[service]="dockerfile:base_image:port"
```

### CPU Services (use `nuniesmith/fks:docker`)
- web, api, app, data, portfolio, monitor, ninja, execution, auth, meta, main

### ML Services (use `nuniesmith/fks:docker-ml`)
- ai, analyze

### GPU Services (use `nuniesmith/fks:docker-gpu`)
- training

## Dockerfile Structure

All service Dockerfiles follow this pattern:

```dockerfile
# Builder stage - uses base image
FROM nuniesmith/fks:docker AS builder  # or docker-ml, docker-gpu

WORKDIR /app
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --user --no-cache-dir -r requirements.txt

# Runtime stage - minimal image
FROM python:3.12-slim

# Copy TA-Lib libraries (if needed)
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/ || true

# Copy Python packages
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser src/ ./src/
```

## Image Tags

All images are tagged as:
- `nuniesmith/fks:<service>-latest` - Latest build
- Base images: `nuniesmith/fks:docker`, `nuniesmith/fks:docker-ml`, `nuniesmith/fks:docker-gpu`

## Local Testing

### Test Base Images

```bash
# Test CPU base
docker run --rm nuniesmith/fks:docker python -c "import talib; print('TA-Lib OK')"

# Test ML base
docker run --rm nuniesmith/fks:docker-ml python -c "import langchain; print('LangChain OK')"

# Test GPU base
docker run --rm nuniesmith/fks:docker-gpu python -c "import torch; print('PyTorch OK')"
```

### Test Service Images

```bash
# Build locally
cd repo/docker
./build-all.sh --service ai

# Test the image
docker run --rm nuniesmith/fks:ai-latest python --version
```

## Maintenance

### When to Rebuild Base Images

1. **Python version update**: Rebuild all bases
2. **TA-Lib version update**: Rebuild CPU base, then ML and GPU bases
3. **LangChain version update**: Rebuild ML base, then GPU base
4. **PyTorch version update**: Rebuild GPU base only
5. **Security patches**: Rebuild affected bases

### Updating Base Images

1. Update the base Dockerfile (e.g., `Dockerfile.ml`)
2. Rebuild the base image
3. Push to DockerHub
4. Service images will use the updated base on next build

### Adding a New Service

1. Create Dockerfile in `repo/docker/` (e.g., `Dockerfile.newservice`)
2. Add to `SERVICE_CONFIG` in `build-all.sh`:
   ```bash
   SERVICE_CONFIG[newservice]="Dockerfile.newservice:nuniesmith/fks:docker:8000"
   ```
3. Test build: `./build-all.sh --service newservice`

## Benefits

1. **Faster Builds**: 50-60% faster build times
   - CPU services: ~1-2 minutes (was ~3-5 minutes)
   - ML services: ~3-5 minutes (was ~8-12 minutes)
   - GPU services: ~5-8 minutes (was ~15-20 minutes)

2. **Smaller Total Size**: 15-20% reduction in total disk usage
   - Base images are shared across services
   - Only service-specific layers are duplicated

3. **Easier Maintenance**: Update packages in one place
   - Base images contain common dependencies
   - Services only need service-specific packages

4. **Consistent Environment**: All services use same package versions
   - Base images ensure consistency
   - Easier to debug and maintain

5. **Better Caching**: Base images cached, service builds are faster
   - Docker layer caching works better
   - CI/CD builds are faster

## Troubleshooting

### Base Image Not Found

If you get "base image not found" errors:
1. Ensure base images are built and pushed to DockerHub
2. Run `docker pull nuniesmith/fks:docker` to verify access
3. Check DockerHub credentials in GitHub Secrets

### Build Failures

1. Check base image exists: `docker pull nuniesmith/fks:docker`
2. Verify Dockerfile uses correct base image
3. Check service requirements.txt doesn't duplicate base packages
4. Review build logs for specific errors

### Image Size Issues

1. Use multi-stage builds (already implemented)
2. Remove unnecessary packages from requirements.txt
3. Use `.dockerignore` to exclude unnecessary files
4. Check base image size: `docker images nuniesmith/fks`

## Related Documentation

- [DOCKER_BASE_STRATEGY.md](./DOCKER_BASE_STRATEGY.md) - Base image strategy details
- [BASE_IMAGES_SUMMARY.md](./BASE_IMAGES_SUMMARY.md) - Base image implementation summary
- [README.md](./README.md) - General Docker build system documentation

## Support

For issues or questions:
1. Check existing documentation
2. Review GitHub Actions workflow logs
3. Test locally with `build-all.sh`
4. Verify base images are up to date


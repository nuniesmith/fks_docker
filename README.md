# FKS Shared Docker Base Images

This directory contains shared base Docker images that multiple FKS services can use to speed up builds and reduce duplication.

## Builder Base Image

The `Dockerfile.builder` creates a base image with:
- **TA-Lib C library** (pre-compiled) - saves ~2-3 minutes per service build
- **Common build tools** (gcc, g++, make, cmake, autotools, etc.)
- **Python build dependencies** (pip, setuptools, wheel)
- **Scientific libraries** (OpenBLAS, LAPACK for numpy/scipy)

### Building the Base Image

```bash
cd repo/docker-base
docker build -t nuniesmith/fks:builder-base -f Dockerfile.builder .
```

### Pushing to Registry

```bash
docker push nuniesmith/fks:builder-base
```

### Using in Services

Update your service Dockerfiles to use the base image:

```dockerfile
# Instead of: FROM python:3.12-slim AS builder
FROM nuniesmith/fks:builder-base AS builder

# TA-Lib is already installed, so skip that step
# Just install Python dependencies
COPY requirements.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --user --no-warn-script-location --no-cache-dir -r requirements.txt
```

## Benefits

1. **Faster Builds**: TA-Lib compilation (~2-3 minutes) happens once, not per service
2. **Smaller Images**: Shared layers reduce total image size
3. **Easier Maintenance**: Update TA-Lib version in one place
4. **Consistent Environment**: All services use the same build tools

## Services That Can Use This Base

- ✅ `fks_ai` - Uses TA-Lib
- ✅ `fks_analyze` - Uses TA-Lib (if needed)
- ✅ `fks_training` - Uses TA-Lib, needs gfortran for scipy
- ✅ `fks_data` - May use TA-Lib
- ✅ Any service that needs TA-Lib or scientific computing libraries

## CI/CD Integration

Add to your GitHub Actions workflow:

```yaml
- name: Build and push builder base
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  run: |
    docker build -t nuniesmith/fks:builder-base -f docker-base/Dockerfile.builder .
    docker push nuniesmith/fks:builder-base
```

Then services can pull it:
```yaml
- name: Pull builder base
  run: docker pull nuniesmith/fks:builder-base || true
```

## Versioning

Tag the base image with versions:
```bash
docker tag nuniesmith/fks:builder-base nuniesmith/fks:builder-base-v1.0.0
docker push nuniesmith/fks:builder-base-v1.0.0
```

This allows services to pin to specific versions if needed.

## Future Enhancements

- **Python Base**: Pre-install common Python packages (numpy, pandas, etc.)
- **GPU Base**: CUDA-enabled base for training service
- **Node Base**: For services that need Node.js
- **Rust Base**: For Rust services (fks_main, fks_auth, etc.)


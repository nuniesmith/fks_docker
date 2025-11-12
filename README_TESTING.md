# FKS Docker Base Images - Local Testing Guide

This guide explains how to build and test Docker base images locally before pushing to DockerHub.

## Quick Start

### 1. Build All Base Images

```bash
# Bash
cd repo/docker
./build-all-bases.sh

# PowerShell
cd repo/docker
.\build-all-bases.ps1
```

This will build:
- CPU Base (`nuniesmith/fks:docker`)
- ML Base (`nuniesmith/fks:docker-ml`)
- GPU Base (`nuniesmith/fks:docker-gpu`)

### 2. Test Base Images with Service Builds

```bash
# Bash
./test-service-builds.sh

# PowerShell
.\test-service-builds.ps1
```

This will test:
- AI service (using ML base)
- Analyze service (using ML base)
- Training service (using GPU base)

### 3. Run Complete Test Suite

```bash
# Bash
./test-all.sh

# PowerShell
.\test-all.ps1
```

This runs both build and test steps in sequence.

## Detailed Testing

### Build Base Images

#### CPU Base

```bash
cd repo/docker
docker build -t nuniesmith/fks:docker -f Dockerfile.builder .
```

**Expected**:
- Build time: ~3-5 minutes
- Image size: ~500-700MB
- Contains: TA-Lib C library, build tools

**Verify**:
```bash
docker run --rm nuniesmith/fks:docker python -c "import sys; print(sys.version)"
docker run --rm nuniesmith/fks:docker ls -la /usr/lib/libta_lib.so*
```

#### ML Base

```bash
cd repo/docker
docker build -t nuniesmith/fks:docker-ml -f Dockerfile.ml .
```

**Expected**:
- Build time: ~5-10 minutes
- Image size: ~2-3GB
- Contains: LangChain, ChromaDB, sentence-transformers

**Verify**:
```bash
docker run --rm nuniesmith/fks:docker-ml python -c "import langchain; import chromadb; import sentence_transformers; print('✅ ML packages installed')"
```

#### GPU Base

```bash
cd repo/docker
docker build -t nuniesmith/fks:docker-gpu -f Dockerfile.gpu .
```

**Expected**:
- Build time: ~10-15 minutes
- Image size: ~5-8GB
- Contains: PyTorch, Transformers, training libraries

**Verify**:
```bash
docker run --rm nuniesmith/fks:docker-gpu python -c "import torch; import transformers; print(f'✅ GPU packages installed (PyTorch {torch.__version__})')"
```

### Test Service Builds

#### AI Service

```bash
cd repo/ai
docker build -t nuniesmith/fks:ai-test .
docker run --rm nuniesmith/fks:ai-test python -c "import langchain; import chromadb; print('✅ AI service works')"
```

#### Analyze Service

```bash
cd repo/analyze
docker build -t nuniesmith/fks:analyze-test .
docker run --rm nuniesmith/fks:analyze-test python -c "import langchain; import chromadb; print('✅ Analyze service works')"
```

#### Training Service

```bash
cd repo/training
docker build -t nuniesmith/fks:training-test .
docker run --rm nuniesmith/fks:training-test python -c "import torch; import transformers; print('✅ Training service works')"
```

## Verification Checklist

### Base Images

- [ ] CPU base builds successfully
- [ ] CPU base contains TA-Lib C library
- [ ] CPU base can run Python commands
- [ ] ML base builds successfully
- [ ] ML base contains LangChain packages
- [ ] ML base contains ChromaDB
- [ ] ML base contains sentence-transformers
- [ ] ML base can run Python commands
- [ ] GPU base builds successfully
- [ ] GPU base contains PyTorch
- [ ] GPU base contains Transformers
- [ ] GPU base contains training libraries
- [ ] GPU base can run Python commands

### Service Images

- [ ] AI service builds with ML base
- [ ] AI service can import LangChain
- [ ] AI service can import ChromaDB
- [ ] AI service health check works
- [ ] Analyze service builds with ML base
- [ ] Analyze service can import LangChain
- [ ] Analyze service can import ChromaDB
- [ ] Analyze service health check works
- [ ] Training service builds with GPU base
- [ ] Training service can import PyTorch
- [ ] Training service can import Transformers
- [ ] Training service health check works

## Build Times

### Expected Build Times

- **CPU Base**: ~3-5 minutes
- **ML Base**: ~5-10 minutes (depends on network speed for package downloads)
- **GPU Base**: ~10-15 minutes (PyTorch is large)
- **AI Service**: ~1-2 minutes (with ML base)
- **Analyze Service**: ~1-2 minutes (with ML base)
- **Training Service**: ~2-3 minutes (with GPU base)

### Actual Build Times

Record your actual build times to compare:
- CPU Base: _____ minutes
- ML Base: _____ minutes
- GPU Base: _____ minutes
- AI Service: _____ minutes
- Analyze Service: _____ minutes
- Training Service: _____ minutes

## Image Sizes

### Expected Image Sizes

- **CPU Base**: ~500-700MB
- **ML Base**: ~2-3GB
- **GPU Base**: ~5-8GB
- **AI Service**: ~2.5-3.5GB (base ~2GB + service ~500MB-1.5GB)
- **Analyze Service**: ~2.5-3.5GB (base ~2GB + service ~500MB-1.5GB)
- **Training Service**: ~6-9GB (base ~5GB + service ~1-4GB)

### Actual Image Sizes

Record your actual image sizes to compare:
- CPU Base: _____ MB
- ML Base: _____ GB
- GPU Base: _____ GB
- AI Service: _____ GB
- Analyze Service: _____ GB
- Training Service: _____ GB

## Troubleshooting

### Base Image Build Fails

1. **Check Docker is running**: `docker info`
2. **Check disk space**: `docker system df`
3. **Check network connectivity**: `ping github.com`
4. **Check TA-Lib download**: The build script tries multiple sources
5. **Check build logs**: Look for specific error messages

### Service Build Fails

1. **Check base image exists**: `docker images nuniesmith/fks:docker-ml`
2. **Check service Dockerfile**: Verify it uses the correct base image
3. **Check requirements.txt**: Verify packages are compatible
4. **Check build logs**: Look for specific error messages

### Package Import Fails

1. **Check base image**: Verify packages are installed in base image
2. **Check requirements.txt**: Verify packages are not duplicated
3. **Check Python path**: Verify PYTHONPATH is set correctly
4. **Check package versions**: Verify version compatibility

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

### Remove Base Images (if needed)

```bash
docker rmi nuniesmith/fks:docker nuniesmith/fks:docker-ml nuniesmith/fks:docker-gpu
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

## Notes

- Base images are built in order: CPU → ML → GPU
- Each base image depends on the previous one
- Service images should pull base images before building
- Test images are tagged with `-test` suffix to avoid conflicts
- Base images can be reused across multiple service builds


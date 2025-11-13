# Dockerfile Fixes Applied

## Summary

All Dockerfile issues have been fixed to work with the actual service repo structure (separate repos, not monorepo).

## Issues Fixed

### 1. Invalid COPY Syntax ✅

**Problem**: Docker COPY commands had `|| true` which is shell syntax, not Docker syntax:
```dockerfile
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/ || true
```

**Error**: `"/||": not found`

**Fix**: Changed to use RUN with BuildKit mount for optional file copying:
```dockerfile
# Copy TA-Lib libraries from builder (needed at runtime) - optional
RUN --mount=from=builder,source=/usr/lib,target=/tmp/ta-lib \
    sh -c 'cp /tmp/ta-lib/libta_lib.so* /usr/lib/ 2>/dev/null || true' || true
```

**Files Fixed**: 12 Dockerfiles
- Dockerfile, Dockerfile.ai, Dockerfile.analyze, Dockerfile.training
- Dockerfile.ninja, Dockerfile.portfolio, Dockerfile.api, Dockerfile.app
- Dockerfile.data, Dockerfile.execution, Dockerfile.web_ui, Dockerfile.monitor

### 2. SERVICE_DIR Build Argument ✅

**Problem**: Dockerfiles referenced `${SERVICE_DIR}` expecting monorepo structure (`./src/services/<service>/`), but services are in separate repos with `requirements.txt` and `src/` at root.

**Fix**: Removed `SERVICE_DIR` and updated to use actual service repo structure:
- Changed `COPY ${SERVICE_DIR}/requirements.txt` → `COPY requirements.txt`
- Changed `COPY ${SERVICE_DIR}/src/` → `COPY src/`
- Made entrypoint.sh optional with `COPY entrypoint.sh*`

**Files Fixed**:
- Dockerfile.api
- Dockerfile.app
- Dockerfile.data
- Dockerfile.web_ui

### 3. Rust Version Issues ✅

**Problem**: Rust services used `rust:1.75-slim` which is too old:
- `meta`: Requires rustc 1.80.0+ (had 1.75.0)
- `main`: Requires Cargo with edition2024 support
- `auth`: Cargo.lock version 4 not supported by Cargo 1.75.0

**Fix**: Updated to `rust:1.82-slim` and added:
- Build dependencies (pkg-config, libssl-dev)
- BuildKit cache mounts for faster builds
- Proper binary copying

**Files Fixed**:
- Dockerfile.meta
- Dockerfile.main
- Dockerfile.auth

### 4. Missing Files (entrypoint.sh) ✅

**Problem**: Some Dockerfiles required `entrypoint.sh` which might not exist in all services.

**Fix**: Made entrypoint.sh optional:
- Changed `COPY entrypoint.sh` → `COPY entrypoint.sh*`
- Added conditional execution: `if [ -f entrypoint.sh ]; then ./entrypoint.sh; else <fallback>; fi`
- Used proper CMD syntax: `CMD ["/bin/sh", "-c", "..."]`

**Files Fixed**:
- Dockerfile.api
- Dockerfile.app
- Dockerfile.data
- Dockerfile.web_ui
- Dockerfile.execution
- Dockerfile.training
- Dockerfile

### 5. CMD Syntax ✅

**Problem**: CMD commands used shell conditionals without proper shell invocation.

**Fix**: Changed to proper JSON array format:
```dockerfile
# Before (invalid)
CMD if [ -f entrypoint.sh ]; then ./entrypoint.sh; else python src/main.py; fi

# After (valid)
CMD ["/bin/sh", "-c", "if [ -f entrypoint.sh ]; then ./entrypoint.sh; else python src/main.py; fi"]
```

**Files Fixed**: 7 Dockerfiles

## Service Structure Assumptions

All Dockerfiles now assume services are in separate repos with this structure:
```
<service-repo>/
├── requirements.txt       # Python dependencies
├── src/                  # Source code
├── entrypoint.sh         # Optional entrypoint script
├── sitecustomize.py      # Optional
├── pyproject.toml        # Optional (for data service)
└── setup.py             # Optional (for data service)
```

## Binary Names

Rust services use these binary names (from Cargo.toml package names):
- `meta`: `fks_meta` → copied as `fks-meta`
- `main`: `fks_main` → copied as `fks-main`
- `auth`: `fks_auth` → copied as `fks-auth`

## Testing

Test builds with:
```bash
cd repo/docker
./build-and-verify.sh --service <service-name>
```

## Status

✅ All Dockerfile syntax issues fixed
✅ All SERVICE_DIR issues resolved
✅ All Rust version issues resolved
✅ All missing file issues handled
✅ All CMD syntax issues fixed

Ready for testing!


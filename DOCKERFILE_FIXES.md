# Dockerfile Fixes Applied

## Issues Fixed

### 1. Invalid COPY Syntax ✅

**Problem**: Docker COPY commands had `|| true` which is shell syntax, not Docker syntax:
```dockerfile
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/ || true
```

**Error**: `"/||": not found`

**Fix Applied**: Changed to use RUN with mount for optional file copying:
```dockerfile
# Copy TA-Lib libraries from builder (needed at runtime) - optional
RUN --mount=from=builder,source=/usr/lib,target=/tmp/ta-lib \
    sh -c 'cp /tmp/ta-lib/libta_lib.so* /usr/lib/ 2>/dev/null || true' || true
```

**Files Fixed**:
- Dockerfile.ai
- Dockerfile.analyze
- Dockerfile.training
- Dockerfile.ninja
- Dockerfile.portfolio
- Dockerfile.api
- Dockerfile.app
- Dockerfile.data
- Dockerfile.execution
- Dockerfile.web_ui
- Dockerfile.monitor

## Remaining Issues

### 2. SERVICE_DIR Build Argument

**Problem**: Some Dockerfiles reference `${SERVICE_DIR}` but it's not passed as a build argument.

**Affected Files**:
- Dockerfile.api
- Dockerfile.app
- Dockerfile.data
- Dockerfile.web_ui

**Solution Needed**: Either:
1. Pass `--build-arg SERVICE_DIR=./src/services/<service>` when building
2. Update Dockerfiles to work with actual service repo structure (not monorepo)

### 3. Rust Version Issues

**Problem**: Rust services need newer Rust toolchain versions.

**Affected Services**:
- meta: Requires rustc 1.80.0+ (has 1.75.0)
- main: Requires Cargo with edition2024 support
- auth: Cargo.lock version 4 not supported by Cargo 1.75.0

**Solution Needed**: Update Rust base images to newer versions:
```dockerfile
FROM rust:1.82-slim  # or latest stable
```

### 4. Missing Files

**Problem**: Some services reference files that don't exist in their repos.

**Examples**:
- execution: `entrypoint.sh` not found

**Solution Needed**: Either create missing files or make them optional in Dockerfiles.

## Testing

After fixes, test builds with:
```bash
cd repo/docker
./build-and-verify.sh --service <service-name>
```

## Next Steps

1. ✅ Fix COPY syntax (DONE)
2. ⏳ Fix SERVICE_DIR issues
3. ⏳ Update Rust toolchain versions
4. ⏳ Handle missing files
5. ⏳ Test all service builds


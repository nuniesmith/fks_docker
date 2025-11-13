# Rust Service Build Fixes

## Issues Fixed

### 1. Rust Version Too Old ✅

**Problem**: 
- `meta` service: `icu_collections@2.1.1` requires `rustc 1.83` but we had `1.82`
- `main` service: `backon v1.6.0` requires `edition2024` which needs Rust 1.83+

**Fix**: Updated Rust Dockerfiles:
- `meta` and `auth`: `rust:1.83-slim` (sufficient for their dependencies)
- `main`: `rust:latest` (required for `home@0.5.12` which needs Rust 1.88+, and `kube v2.0.1`/`backon v1.6.0`)

**Files Updated**:
- `Dockerfile.meta` → `rust:1.83-slim`
- `Dockerfile.main` → `rust:latest` (needs Rust 1.88+ for `home@0.5.12`, `kube v2.0.1`, and `backon v1.6.0`)
- `Dockerfile.auth` → `rust:1.83-slim`

### 2. Binary Not Found in COPY Step ✅

**Problem**: 
- Build succeeded but COPY step failed: `/app/target/release/fks_auth: not found`
- This happens because cache mounts make the `target/` directory not directly accessible in COPY steps

**Fix**: Copy the binary to a known location (`/app/`) during the build step, then COPY from that location

**Solution**:
```dockerfile
# During build, copy binary to /app/ (outside cache mount)
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release && \
    cp target/release/fks_auth /app/fks-auth || \
    find target/release -name fks_auth -type f -exec cp {} /app/fks-auth \;

# Then COPY from the known location
COPY --from=builder /app/fks-auth /app/fks-auth
```

**Files Updated**:
- `Dockerfile.meta` - copies to `/app/fks-meta`
- `Dockerfile.main` - copies to `/app/fks-main`
- `Dockerfile.auth` - copies to `/app/fks-auth`

## Binary Names

Rust services use these binary names (from Cargo.toml package names):
- `meta`: package `fks_meta` → binary `fks_meta` → copied as `fks-meta`
- `main`: package `fks_main` → binary `fks_main` → copied as `fks-main`
- `auth`: package `fks_auth` → binary `fks_auth` → copied as `fks-auth`

## Testing

Test builds with:
```bash
cd repo/docker
./build-and-verify.sh --service meta
./build-and-verify.sh --service main
./build-and-verify.sh --service auth
```

## Status

✅ Rust versions updated:
  - `meta` & `auth`: `rust:1.83-slim`
  - `main`: `rust:latest` (1.88+)
✅ Binary copy issue fixed for all Rust services
✅ Verification timeout added (5 seconds max)
⏳ Ready for testing


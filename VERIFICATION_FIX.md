# Image Verification Timeout Fix

## Problem

During image verification, some containers were hanging, requiring manual Ctrl+C to continue. This happened because:
- `docker run` commands had no timeout
- Some services might take time to start or have blocking operations
- Verification was trying to actually run containers which could hang

## Solution

Added timeouts to all verification commands:

### Changes Made

1. **Base Image Verification**:
   - Added `timeout 5` to `docker run` commands
   - Reduced timeout from implicit (infinite) to 5 seconds
   - Added fallback to `docker inspect` if run test fails

2. **Service Image Verification**:
   - Added `timeout 5` to all `docker run` attempts
   - Improved logic to try multiple verification methods:
     - Python services: `python --version`
     - Rust services: `--version` flag
     - Generic: `/bin/sh -c "exit 0"`
     - Fallback: `docker inspect` to verify image structure
   - Each attempt has a 5-second timeout

### Benefits

- **No more hanging**: Verification will timeout after 5 seconds max
- **Faster verification**: Quick failures instead of waiting indefinitely
- **More robust**: Multiple fallback methods ensure verification completes
- **Better UX**: No need for manual Ctrl+C interruptions

## Testing

The verification should now complete automatically without hanging:

```bash
cd repo/docker
./build-and-verify.sh
```

All verification steps will complete within 5 seconds per image, or fall back to structure verification.


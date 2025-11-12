# FKS Web Service - Uses CPU Base Image
# Multi-stage build using CPU base image with TA-Lib and build tools pre-installed
FROM nuniesmith/fks:docker AS builder

# Set work directory
WORKDIR /app

# TA-Lib and build tools are already installed in base image
# Copy requirements files (use dev requirements - excludes GPU packages like PyTorch)
COPY requirements.txt requirements.dev.txt* .

# Install Python dependencies with BuildKit cache mount
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --user --no-warn-script-location --no-cache-dir -r requirements.txt && \
    if [ -f requirements.dev.txt ]; then \
        python -m pip install --user --no-warn-script-location --no-cache-dir -r requirements.dev.txt; \
    fi

# Runtime stage
FROM python:3.12-slim

# Set environment variables for runtime
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    SERVICE_NAME=fks_web \
    SERVICE_PORT=3001 \
    PYTHONPATH=/app/src:/app \
    PATH=/home/appuser/.local/bin:$PATH

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -u 1000 -m -s /bin/bash appuser

# Copy TA-Lib libraries from builder
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/ || true

# Copy Python packages from builder
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Set work directory
WORKDIR /app

# Copy application code
COPY --chown=appuser:appuser src/ ./src/
COPY --chown=appuser:appuser entrypoint.sh* ./

# Make entrypoint executable if it exists
RUN if [ -f entrypoint.sh ]; then chmod +x entrypoint.sh; fi

# Switch to non-root user
USER appuser

EXPOSE 3001

# Use entrypoint script if available, otherwise run gunicorn
CMD if [ -f entrypoint.sh ]; then ./entrypoint.sh; else gunicorn config.wsgi:application --bind 0.0.0.0:3001; fi
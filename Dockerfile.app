# FKS App - Business Logic Service Dockerfile
# Uses CPU base image with TA-Lib and build tools pre-installed
FROM nuniesmith/fks:docker AS builder

ARG SERVICE_DIR=./src/services/app

# Set working directory
WORKDIR /app

# TA-Lib and build tools are already installed in base image
# Just install service-specific packages
COPY ${SERVICE_DIR}/requirements.txt .

# Install Python dependencies with BuildKit cache mount
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --user --no-warn-script-location --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.12-slim

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    SERVICE_NAME=fks_app \
    SERVICE_PORT=8002 \
    PYTHONPATH=/app/src:/app \
    PATH=/home/appuser/.local/bin:$PATH

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -u 1000 -m -s /bin/bash appuser

# Copy TA-Lib libraries from builder (needed at runtime)
COPY --from=builder /usr/lib/libta_lib.so* /usr/lib/ || true

# Copy Python packages from builder
COPY --from=builder --chown=appuser:appuser /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser ${SERVICE_DIR}/src/ ./src/

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
  CMD python -c "import os,urllib.request,sys;port=os.getenv('SERVICE_PORT','8002');u=f'http://localhost:{port}/health';\
import urllib.error;\
try: urllib.request.urlopen(u,timeout=3);\
except Exception: sys.exit(1)" || exit 1

# Run FastAPI with uvicorn  
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8002"]

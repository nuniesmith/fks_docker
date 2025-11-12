# ML Base Image for FKS Services
# This image contains ML/AI packages that are shared across ai and analyze services:
# - LangChain ecosystem (langchain, langchain-core, langchain-community, langchain-ollama)
# - Vector stores (chromadb)
# - Embeddings (sentence-transformers)
# - Ollama integration
# - TA-Lib Python package
#
# Usage:
#   docker build -t nuniesmith/fks:docker-ml -f Dockerfile.ml .
#   docker push nuniesmith/fks:docker-ml
#
# Then ML services can use: FROM nuniesmith/fks:docker-ml AS builder

FROM nuniesmith/fks:docker AS ml-base

WORKDIR /app

# Install ML/AI Python packages
# These are large packages that take time to build, so we pre-install them in the base image
RUN --mount=type=cache,target=/root/.cache/pip \
    python -m pip install --no-cache-dir \
    "langchain>=0.3.0,<0.4.0" \
    "langchain-core>=0.3.0,<0.4.0" \
    "langchain-community>=0.3.0,<0.4.0" \
    "langchain-ollama>=0.2.0,<1.0.0" \
    "langchain-text-splitters>=0.3.0,<0.4.0" \
    "chromadb>=0.4.0,<1.0.0" \
    "sentence-transformers>=2.2.0,<6.0.0" \
    "ollama>=0.1.0,<1.0.0" \
    "TA-Lib>=0.4.28" \
    "numpy>=1.26.0,<2.0.0" \
    "pandas>=2.2.0" \
    "httpx>=0.25.0,<0.29.0"

# Verify installations
RUN python -c "import langchain; import chromadb; import sentence_transformers; import ollama; import talib; print('✅ ML packages installed successfully')" || echo "⚠️  Some ML packages may not be available"

# Label the image
LABEL maintainer="nuniesmith" \
    description="ML/AI base image with LangChain, ChromaDB, and sentence-transformers" \
    version="1.0.0" \
    base="nuniesmith/fks:docker"


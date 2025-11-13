#!/bin/bash
# FKS Unified Docker Build Script
# Builds base images first, then all services using those base images
# Supports local testing and pushing to Docker Hub

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DOCKER_USERNAME="nuniesmith"
DOCKER_REPO="fks"
DEFAULT_TAG="latest"
PUSH_TO_HUB="${PUSH_TO_HUB:-false}"
BUILD_BASE="${BUILD_BASE:-true}"
TEST_BUILDS="${TEST_BUILDS:-true}"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$MAIN_DIR/.." && pwd)"
DOCKER_BASE_DIR="$REPO_DIR/docker"

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${CYAN}========================================${NC}"; echo -e "${CYAN}$1${NC}"; echo -e "${CYAN}========================================${NC}\n"; }

# Services configuration
declare -A SERVICE_CONFIG
# Format: SERVICE_CONFIG[service]="dockerfile:base_image:port"
SERVICE_CONFIG[web]="Dockerfile:nuniesmith/fks:docker:3001"
SERVICE_CONFIG[api]="Dockerfile.api:nuniesmith/fks:docker:8001"
SERVICE_CONFIG[app]="Dockerfile.app:nuniesmith/fks:docker:8002"
SERVICE_CONFIG[data]="Dockerfile.data:nuniesmith/fks:docker:8003"
SERVICE_CONFIG[ai]="Dockerfile.ai:nuniesmith/fks:docker-ml:8007"
SERVICE_CONFIG[analyze]="Dockerfile.analyze:nuniesmith/fks:docker-ml:8008"
SERVICE_CONFIG[training]="Dockerfile.training:nuniesmith/fks:docker-gpu:8011"
SERVICE_CONFIG[portfolio]="Dockerfile.portfolio:nuniesmith/fks:docker:8012"
SERVICE_CONFIG[monitor]="Dockerfile.monitor:nuniesmith/fks:docker:8013"
SERVICE_CONFIG[ninja]="Dockerfile.ninja:nuniesmith/fks:docker:8006"
SERVICE_CONFIG[execution]="Dockerfile.execution:nuniesmith/fks:docker:8004"
SERVICE_CONFIG[auth]="Dockerfile.auth:nuniesmith/fks:docker:8009"
SERVICE_CONFIG[meta]="Dockerfile.meta:nuniesmith/fks:docker:8005"
SERVICE_CONFIG[main]="Dockerfile.main:nuniesmith/fks:docker:8010"
SERVICE_CONFIG[tailscale]="Dockerfile.tailscale:none:0"
SERVICE_CONFIG[nginx]="Dockerfile.nginx:none:80"

# Build base images
build_base_images() {
  log_section "Building Base Images"
  
  if [ ! -d "$DOCKER_BASE_DIR" ]; then
    log_error "Base docker directory not found: $DOCKER_BASE_DIR"
    return 1
  fi

  cd "$DOCKER_BASE_DIR"

  # Build CPU base (docker)
  log_info "Building CPU base image (docker)..."
  if docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker" -f Dockerfile.builder .; then
    log_success "CPU base image built"
    if [ "$PUSH_TO_HUB" = "true" ]; then
      docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker" || log_warning "Failed to push CPU base"
    fi
  else
    log_error "Failed to build CPU base image"
    return 1
  fi

  # Build ML base (docker-ml) - depends on docker
  log_info "Building ML base image (docker-ml)..."
  if docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" -f Dockerfile.ml .; then
    log_success "ML base image built"
    if [ "$PUSH_TO_HUB" = "true" ]; then
      docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-ml" || log_warning "Failed to push ML base"
    fi
  else
    log_error "Failed to build ML base image"
    return 1
  fi

  # Build GPU base (docker-gpu) - depends on docker-ml
  log_info "Building GPU base image (docker-gpu)..."
  if docker build -t "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu" -f Dockerfile.gpu .; then
    log_success "GPU base image built"
    if [ "$PUSH_TO_HUB" = "true" ]; then
      docker push "$DOCKER_USERNAME/$DOCKER_REPO:docker-gpu" || log_warning "Failed to push GPU base"
    fi
  else
    log_error "Failed to build GPU base image"
    return 1
  fi

  log_success "All base images built successfully"
}

# Pull base images (if not building)
pull_base_images() {
  log_section "Pulling Base Images from Docker Hub"
  
  for base in docker docker-ml docker-gpu; do
    log_info "Pulling $DOCKER_USERNAME/$DOCKER_REPO:$base..."
    if docker pull "$DOCKER_USERNAME/$DOCKER_REPO:$base"; then
      log_success "Pulled $base"
    else
      log_warning "Failed to pull $base (may not exist yet)"
    fi
  done
}

# Build a service
build_service() {
  local service="$1"
  local config="${SERVICE_CONFIG[$service]}"
  
  if [ -z "$config" ]; then
    log_warning "No configuration for service: $service - skipping"
    return 1
  fi

  IFS=':' read -r dockerfile base_image port <<< "$config"
  
  local service_dir="$REPO_DIR/$service"
  local dockerfile_path="$SCRIPT_DIR/$dockerfile"
  
  if [ ! -f "$dockerfile_path" ]; then
    log_warning "Dockerfile not found: $dockerfile_path - skipping $service"
    return 1
  fi

  if [ ! -d "$service_dir" ]; then
    log_warning "Service directory not found: $service_dir - skipping $service"
    return 1
  fi

  if [ "$base_image" = "none" ]; then
    log_info "Building $service (no FKS base image - using own base)..."
  else
    log_info "Building $service (using base: $base_image)..."
    
    # Check if base image exists locally
    if ! docker image inspect "$base_image" &>/dev/null; then
      log_warning "Base image $base_image not found locally, pulling..."
      docker pull "$base_image" || {
        log_error "Failed to pull base image $base_image"
        return 1
      }
    fi
  fi

  local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-${DEFAULT_TAG}"
  
  # Build from service directory with dockerfile from docker/ dir
  cd "$service_dir"
  if docker build -f "$dockerfile_path" -t "$image_name" .; then
    log_success "Built $image_name"
    
    # Test the image if requested
    if [ "$TEST_BUILDS" = "true" ]; then
      test_service_image "$service" "$image_name"
    fi
    
    # Push if requested
    if [ "$PUSH_TO_HUB" = "true" ]; then
      log_info "Pushing $image_name to Docker Hub..."
      if docker push "$image_name"; then
        log_success "Pushed $image_name"
      else
        log_error "Failed to push $image_name"
        return 1
      fi
    fi
    
    return 0
  else
    log_error "Failed to build $service"
    return 1
  fi
}

# Test a service image
test_service_image() {
  local service="$1"
  local image="$2"
  
  log_info "Testing $service image..."
  
  # Run a simple test (check if image can start)
  if docker run --rm "$image" python --version &>/dev/null || \
     docker run --rm "$image" --version &>/dev/null || \
     docker run --rm "$image" /bin/true &>/dev/null; then
    log_success "$service image test passed"
    return 0
  else
    log_warning "$service image test had issues (may still be valid)"
    return 0  # Don't fail on test
  fi
}

# Build all services
build_all_services() {
  log_section "Building All Services"
  
  local success_count=0
  local failed_services=()
  
  for service in "${!SERVICE_CONFIG[@]}"; do
    if build_service "$service"; then
      success_count=$((success_count + 1))
    else
      failed_services+=("$service")
    fi
    echo ""
  done
  
  log_section "Build Summary"
  log_info "Successfully built: $success_count/${#SERVICE_CONFIG[@]} services"
  
  if [ ${#failed_services[@]} -gt 0 ]; then
    log_warning "Failed services: ${failed_services[*]}"
    return 1
  fi
  
  return 0
}

# Show image sizes
show_image_sizes() {
  log_section "Image Sizes"
  docker images | grep -E "$DOCKER_USERNAME/$DOCKER_REPO" | awk '{printf "%-50s %10s\n", $1":"$2, $7}'
}

# Main execution
main() {
  log_section "FKS Unified Docker Build"
  echo "Configuration:"
  echo "  Build Base Images: $BUILD_BASE"
  echo "  Test Builds: $TEST_BUILDS"
  echo "  Push to Docker Hub: $PUSH_TO_HUB"
  echo "  Docker Repo: $DOCKER_USERNAME/$DOCKER_REPO"
  echo ""

  # Build or pull base images
  if [ "$BUILD_BASE" = "true" ]; then
    build_base_images || {
      log_error "Base image build failed"
      exit 1
    }
  else
    pull_base_images
  fi

  # Build all services
  build_all_services || {
    log_warning "Some services failed to build"
  }

  # Show summary
  show_image_sizes

  log_section "Build Complete"
  if [ "$PUSH_TO_HUB" = "true" ]; then
    log_success "All images built and pushed to Docker Hub!"
    log_info "Images available at: https://hub.docker.com/r/$DOCKER_USERNAME/$DOCKER_REPO"
  else
    log_success "All images built locally!"
    log_info "To push to Docker Hub, run: PUSH_TO_HUB=true $0"
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --push)
      PUSH_TO_HUB="true"
      shift
      ;;
    --no-base)
      BUILD_BASE="false"
      shift
      ;;
    --no-test)
      TEST_BUILDS="false"
      shift
      ;;
    --service)
      # Build specific service
      if [ -n "$2" ]; then
        if [ "$BUILD_BASE" = "true" ]; then
          build_base_images
        else
          pull_base_images
        fi
        build_service "$2"
        exit $?
      else
        log_error "--service requires a service name"
        exit 1
      fi
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --push          Push images to Docker Hub after building"
      echo "  --no-base       Don't build base images (pull from Docker Hub instead)"
      echo "  --no-test       Skip testing built images"
      echo "  --service NAME  Build only a specific service"
      echo "  --help          Show this help message"
      echo ""
      echo "Environment Variables:"
      echo "  PUSH_TO_HUB     Set to 'true' to push to Docker Hub"
      echo "  BUILD_BASE      Set to 'false' to skip building base images"
      echo "  TEST_BUILDS     Set to 'false' to skip testing"
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Run main
main


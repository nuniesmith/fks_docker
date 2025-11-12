#!/bin/bash
# FKS Docker Build Test Script
# Tests building all services locally to ensure base images work correctly

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

# Services configuration (same as build-all.sh)
declare -A SERVICE_CONFIG
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

# Test base images exist
test_base_images() {
  log_section "Testing Base Images"
  
  local missing_bases=()
  
  for base in docker docker-ml docker-gpu; do
    if docker image inspect "$DOCKER_USERNAME/$DOCKER_REPO:$base" &>/dev/null; then
      log_success "Base image exists: $base"
    else
      log_warning "Base image missing: $base"
      missing_bases+=("$base")
    fi
  done
  
  if [ ${#missing_bases[@]} -gt 0 ]; then
    log_error "Missing base images: ${missing_bases[*]}"
    log_info "Build base images first with: cd $DOCKER_BASE_DIR && ./build-all-bases.sh"
    return 1
  fi
  
  return 0
}

# Test building a service
test_build_service() {
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

  log_info "Testing build for $service..."
  
  # Check if base image exists
  if ! docker image inspect "$base_image" &>/dev/null; then
    log_error "Base image $base_image not found for $service"
    return 1
  fi

  local image_name="$DOCKER_USERNAME/$DOCKER_REPO:${service}-test"
  
  # Build from service directory
  cd "$service_dir"
  if docker build -f "$dockerfile_path" -t "$image_name" . 2>&1 | tee /tmp/build-${service}.log; then
    log_success "$service built successfully"
    
    # Test image size
    local size=$(docker images "$image_name" --format "{{.Size}}")
    log_info "$service image size: $size"
    
    # Clean up test image
    docker rmi "$image_name" &>/dev/null || true
    
    return 0
  else
    log_error "$service build failed - check /tmp/build-${service}.log"
    return 1
  fi
}

# Test all services
test_all_services() {
  log_section "Testing All Service Builds"
  
  local success_count=0
  local failed_services=()
  
  for service in "${!SERVICE_CONFIG[@]}"; do
    if test_build_service "$service"; then
      success_count=$((success_count + 1))
    else
      failed_services+=("$service")
    fi
    echo ""
  done
  
  log_section "Test Summary"
  log_info "Successfully built: $success_count/${#SERVICE_CONFIG[@]} services"
  
  if [ ${#failed_services[@]} -gt 0 ]; then
    log_error "Failed services: ${failed_services[*]}"
    log_info "Check build logs in /tmp/build-*.log"
    return 1
  fi
  
  return 0
}

# Show image size comparison
show_size_comparison() {
  log_section "Image Size Analysis"
  
  log_info "Base Images:"
  docker images | grep -E "$DOCKER_USERNAME/$DOCKER_REPO:(docker|docker-ml|docker-gpu)" | awk '{printf "  %-30s %10s\n", $1":"$2, $7}'
  
  echo ""
  log_info "Service Images (if built):"
  docker images | grep -E "$DOCKER_USERNAME/$DOCKER_REPO:.*-test" | awk '{printf "  %-30s %10s\n", $1":"$2, $7}' || log_info "  (No test images found - run builds first)"
}

# Main execution
main() {
  log_section "FKS Docker Build Test"
  
  # Test base images
  if ! test_base_images; then
    log_error "Base images not available. Build them first."
    exit 1
  fi
  
  # Test all service builds
  if ! test_all_services; then
    log_error "Some service builds failed"
    exit 1
  fi
  
  # Show size comparison
  show_size_comparison
  
  log_section "Test Complete"
  log_success "All builds passed! ✅"
  log_info "Base images are working correctly"
  log_info "All services can build using base images"
  log_info "Ready to push to Docker Hub"
}

# Run main
main


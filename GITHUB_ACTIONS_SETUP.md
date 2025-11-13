# GitHub Actions Setup for Docker Builds

## Overview

The FKS Docker repository includes GitHub Actions workflows to automatically build and push Docker images for all services to DockerHub.

## Workflows

### 1. Build Base Images (`build-base.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual workflow dispatch

**What it does:**
- Builds CPU base image (`nuniesmith/fks:docker`)
- Builds ML base image (`nuniesmith/fks:docker-ml`) - depends on CPU base
- Builds GPU base image (`nuniesmith/fks:docker-gpu`) - depends on ML base

**Images created:**
- `nuniesmith/fks:docker` / `nuniesmith/fks:docker-latest`
- `nuniesmith/fks:docker-ml` / `nuniesmith/fks:docker-ml-latest`
- `nuniesmith/fks:docker-gpu` / `nuniesmith/fks:docker-gpu-latest`

### 2. Build All Services (`build-all-services.yml`)

**Triggers:**
- Push to `main` or `develop` branches (when Dockerfiles change)
- Pull requests to `main`
- Manual workflow dispatch (with optional service filter)

**What it does:**
- Checks out docker repo and each service repo individually
- Builds and pushes all service images in parallel
- Each service job is independent and can run concurrently

**Services built:**
- `web`, `api`, `app`, `data`, `ai`, `analyze`, `training`, `portfolio`
- `monitor`, `ninja`, `execution`, `auth`, `meta`, `main`
- `tailscale`, `nginx` (newly added)

**Images created:**
- `nuniesmith/fks:<service>-latest` for each service

**Manual trigger:**
You can trigger this workflow manually and optionally specify a single service to build:
- Go to Actions → Build and Push All Service Images → Run workflow
- Select service (or leave empty for all)

### 3. Build Services (Script-based) (`build-services.yml`)

**Triggers:**
- Push to `main` branch (when Dockerfiles or build-all.sh change)
- Daily schedule (2 AM UTC)
- Manual workflow dispatch

**What it does:**
- Uses the `build-all.sh` script to build services
- Note: This workflow requires all service repos to be available as siblings to the docker repo
- Currently configured but may need adjustment for monorepo vs multi-repo setup

## Required Secrets

Make sure these secrets are configured in your GitHub repository:

1. **`DOCKER_TOKEN`** - DockerHub access token
   - Create at: https://hub.docker.com/settings/security
   - Needs write permissions to push images

2. **`GITHUB_TOKEN`** - Automatically provided by GitHub Actions
   - No configuration needed - GitHub Actions automatically provides this
   - Has access to checkout repos in the same organization

## Repository Structure

The workflows assume:
- Docker repo: `github.com/<owner>/docker`
- Service repos: `github.com/<owner>/<service-name>`
  - e.g., `github.com/<owner>/api`, `github.com/<owner>/web`, etc.

## Workflow Execution

### Automatic Builds

**Base Images:**
- Automatically built when you push to `main` or `develop` in the docker repo
- Build in sequence: CPU → ML → GPU

**Service Images:**
- Automatically built when Dockerfiles change in the docker repo
- All services build in parallel (independent jobs)
- Each service checks out its own repo and the docker repo

### Manual Builds

1. **Build Base Images:**
   - Go to Actions → Build and Push Docker Base Images
   - Click "Run workflow"
   - Select branch and run

2. **Build All Services:**
   - Go to Actions → Build and Push All Service Images
   - Click "Run workflow"
   - Optionally select a specific service to build
   - Select branch and run

3. **Build Services (Script):**
   - Go to Actions → Build and Push Service Images
   - Click "Run workflow"
   - Optionally select a specific service
   - Select branch and run

## Image Naming Convention

All images follow this pattern:
- Base images: `nuniesmith/fks:<base-type>`
- Service images: `nuniesmith/fks:<service-name>-latest`

Examples:
- `nuniesmith/fks:docker` (CPU base)
- `nuniesmith/fks:docker-ml` (ML base)
- `nuniesmith/fks:docker-gpu` (GPU base)
- `nuniesmith/fks:api-latest` (API service)
- `nuniesmith/fks:tailscale-latest` (Tailscale service)
- `nuniesmith/fks:nginx-latest` (Nginx service)

## Caching

All workflows use GitHub Actions cache for:
- Docker layer caching (via `cache-from` and `cache-to`)
- Build artifacts
- Dependencies

This significantly speeds up subsequent builds.

## Troubleshooting

### Build Failures

1. **Base image not found:**
   - Ensure base images are built first
   - Check `build-base.yml` workflow completed successfully

2. **Service repo not found:**
   - Verify service repo exists and is accessible
   - Ensure repos are in the same GitHub organization
   - Verify repository name matches exactly

3. **Docker login failed:**
   - Check `DOCKER_TOKEN` secret is set correctly
   - Verify token has write permissions
   - Token should be a DockerHub access token, not password

4. **Build context issues:**
   - Ensure required files exist in service repos
   - Check `.dockerignore` files don't exclude needed files
   - Verify Dockerfile paths are correct

### Performance

- Base images build sequentially (required dependency chain)
- Service images build in parallel (independent)
- Use cache to speed up builds
- Consider building only changed services manually

## Next Steps

1. **Push changes to trigger builds:**
   ```bash
   git add .
   git commit -m "Add tailscale and nginx to GitHub Actions workflows"
   git push origin main
   ```

2. **Monitor builds:**
   - Go to Actions tab in GitHub
   - Watch workflows execute
   - Check for any failures

3. **Verify images:**
   - Check DockerHub: https://hub.docker.com/r/nuniesmith/fks/tags
   - Verify all service images are present
   - Test pulling images: `docker pull nuniesmith/fks:api-latest`

4. **Update K8s deployments:**
   - Once images are pushed, update K8s manifests to use new images
   - Deploy updated services

## Notes

- Base images must be built before service images
- Service images can be built independently
- All images are tagged with `-latest` for consistency
- Workflows use GitHub Actions cache for faster builds
- Pull requests build but don't push images (safety)


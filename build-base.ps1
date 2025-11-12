# Build script for FKS shared builder base image (PowerShell)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

Write-Host "Building FKS shared builder base image..."
Write-Host "Repository root: $RepoRoot"

Set-Location $ScriptDir

# Build the base image
docker build -t nuniesmith/fks:builder-base -f Dockerfile.builder .

Write-Host ""
Write-Host "✅ Builder base image built successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Image: nuniesmith/fks:builder-base"
Write-Host ""
Write-Host "To push to registry:"
Write-Host "  docker push nuniesmith/fks:builder-base"
Write-Host ""
Write-Host "To use in services, update Dockerfiles to:"
Write-Host "  FROM nuniesmith/fks:builder-base AS builder"


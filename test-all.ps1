# Complete test suite for Docker base images (PowerShell)
# This script builds all base images and tests them with service builds

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FKS Docker Base Images - Complete Test Suite" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build all base images
Write-Host "Step 1: Building all base images..." -ForegroundColor Cyan
& .\build-all-bases.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Base image build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Testing base images with service builds..." -ForegroundColor Cyan
& .\test-service-builds.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Service build test failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "All Tests Passed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:"
Write-Host "  ✅ Base images built successfully"
Write-Host "  ✅ Service images built successfully"
Write-Host "  ✅ All tests passed"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Review test results"
Write-Host "  2. Clean up test images (run cleanup-test-images.ps1)"
Write-Host "  3. Push base images to DockerHub (if ready)"
Write-Host ""


# Test base images by building service images with them (PowerShell)
# This script builds service images using the new base images and verifies they work

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

$ImageName = "nuniesmith/fks"
$TestTagSuffix = "-test"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FKS Service Build Tests with Base Images" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Check-BaseImage {
    param([string]$Tag)
    
    $ImageExists = docker image inspect $Tag 2>&1
    return $LASTEXITCODE -eq 0
}

function Build-ServiceImage {
    param(
        [string]$Service,
        [string]$ServiceDir,
        [string]$BaseImage,
        [string]$TestTag
    )
    
    Write-Host "Testing $Service service with base image: $BaseImage" -ForegroundColor Cyan
    Write-Host "  Service directory: $ServiceDir"
    Write-Host "  Test tag: $TestTag"
    Write-Host ""
    
    # Check if base image exists
    if (-not (Check-BaseImage $BaseImage)) {
        Write-Host "❌ Base image not found: $BaseImage" -ForegroundColor Red
        Write-Host "   Please build base images first: ./build-all-bases.ps1" -ForegroundColor Yellow
        return $false
    }
    
    # Check if service directory exists
    if (-not (Test-Path $ServiceDir)) {
        Write-Host "❌ Service directory not found: $ServiceDir" -ForegroundColor Red
        return $false
    }
    
    # Check if Dockerfile exists
    if (-not (Test-Path "$ServiceDir/Dockerfile")) {
        Write-Host "❌ Dockerfile not found: $ServiceDir/Dockerfile" -ForegroundColor Red
        return $false
    }
    
    $StartTime = Get-Date
    
    # Build the service image
    Push-Location $ServiceDir
    try {
        docker build -t $TestTag . 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $EndTime = Get-Date
            $Duration = ($EndTime - $StartTime).TotalSeconds
            $ImageSize = docker images $TestTag --format "{{.Size}}" 2>&1
            
            Write-Host "✅ $Service service image built successfully!" -ForegroundColor Green
            Write-Host "  Build time: $([math]::Round($Duration, 2))s"
            Write-Host "  Image size: $ImageSize"
            Write-Host "  Test tag: $TestTag"
            Write-Host ""
            
            # Test the service image
            Write-Host "Testing $Service service image..." -ForegroundColor Yellow
            $TestResult = docker run --rm $TestTag python -c "import sys; print(f'Python {sys.version}')" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ $Service service image can run Python commands" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ $Service service image cannot run Python commands" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ $Service service image build failed!" -ForegroundColor Red
            return $false
        }
    } finally {
        Pop-Location
    }
}

# Check if base images exist
Write-Host "Checking base images..." -ForegroundColor Yellow
if (-not (Check-BaseImage "${ImageName}:docker")) {
    Write-Host "❌ CPU base image not found: ${ImageName}:docker" -ForegroundColor Red
    Write-Host "   Please build base images first: ./build-all-bases.ps1" -ForegroundColor Yellow
    exit 1
}

if (-not (Check-BaseImage "${ImageName}:docker-ml")) {
    Write-Host "❌ ML base image not found: ${ImageName}:docker-ml" -ForegroundColor Red
    Write-Host "   Please build base images first: ./build-all-bases.ps1" -ForegroundColor Yellow
    exit 1
}

if (-not (Check-BaseImage "${ImageName}:docker-gpu")) {
    Write-Host "❌ GPU base image not found: ${ImageName}:docker-gpu" -ForegroundColor Red
    Write-Host "   Please build base images first: ./build-all-bases.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ All base images found" -ForegroundColor Green
Write-Host ""

# Test ML services (using ML base)
Write-Host "=== Testing ML Services ===" -ForegroundColor Yellow
$AISuccess = Build-ServiceImage "ai" "$RepoRoot\repo\ai" "${ImageName}:docker-ml" "${ImageName}:ai${TestTagSuffix}"
$AnalyzeSuccess = Build-ServiceImage "analyze" "$RepoRoot\repo\analyze" "${ImageName}:docker-ml" "${ImageName}:analyze${TestTagSuffix}"

# Test GPU services (using GPU base)
Write-Host "=== Testing GPU Services ===" -ForegroundColor Yellow
$TrainingSuccess = Build-ServiceImage "training" "$RepoRoot\repo\training" "${ImageName}:docker-gpu" "${ImageName}:training${TestTagSuffix}"

# Summary
Write-Host ""
if ($AISuccess -and $AnalyzeSuccess -and $TrainingSuccess) {
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "All Service Build Tests Passed!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Test Images:"
    docker images "${ImageName}:ai${TestTagSuffix}" "${ImageName}:analyze${TestTagSuffix}" "${ImageName}:training${TestTagSuffix}" --format "  {{.Repository}}:{{.Tag}} - {{.Size}}"
    Write-Host ""
    Write-Host "Next Steps:"
    Write-Host "  1. Verify service images work correctly"
    Write-Host "  2. Test service functionality"
    Write-Host "  3. Clean up test images"
    Write-Host "  4. Push base images to DockerHub (if tests pass)"
    Write-Host ""
    exit 0
} else {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "Some Service Build Tests Failed!" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Failed Tests:"
    if (-not $AISuccess) { Write-Host "  - AI service" -ForegroundColor Red }
    if (-not $AnalyzeSuccess) { Write-Host "  - Analyze service" -ForegroundColor Red }
    if (-not $TrainingSuccess) { Write-Host "  - Training service" -ForegroundColor Red }
    Write-Host ""
    exit 1
}


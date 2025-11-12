# Build all Docker base images locally for testing (PowerShell)
# This script builds CPU, ML, and GPU base images in order

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$ImageName = "nuniesmith/fks"
$Registry = if ($env:DOCKER_REGISTRY) { $env:DOCKER_REGISTRY } else { "docker.io" }

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FKS Docker Base Images - Local Build" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Build-BaseImage {
    param(
        [string]$Name,
        [string]$Dockerfile,
        [string]$Tag,
        [string]$Description
    )
    
    Write-Host "Building $Name base image..." -ForegroundColor Yellow
    Write-Host "  Dockerfile: $Dockerfile"
    Write-Host "  Tag: $Tag"
    Write-Host "  Description: $Description"
    Write-Host ""
    
    $StartTime = Get-Date
    
    try {
        docker build -t $Tag -f $Dockerfile . 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $EndTime = Get-Date
            $Duration = ($EndTime - $StartTime).TotalSeconds
            $ImageSize = docker images $Tag --format "{{.Size}}" 2>&1
            
            Write-Host "✅ $Name base image built successfully!" -ForegroundColor Green
            Write-Host "  Build time: $([math]::Round($Duration, 2))s"
            Write-Host "  Image size: $ImageSize"
            Write-Host "  Tag: $Tag"
            Write-Host ""
            
            # Verify the image exists
            $ImageExists = docker image inspect $Tag 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Image verified: $Tag" -ForegroundColor Green
                return $true
            } else {
                Write-Host "❌ Image verification failed: $Tag" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "❌ $Name base image build failed!" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "❌ Error building $Name base image: $_" -ForegroundColor Red
        return $false
    }
}

function Verify-BaseImage {
    param(
        [string]$Tag
    )
    
    Write-Host "Verifying base image: $Tag" -ForegroundColor Yellow
    
    # Check if image exists
    $ImageExists = docker image inspect $Tag 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Image not found: $Tag" -ForegroundColor Red
        return $false
    }
    
    # Try to run a test command
    $TestResult = docker run --rm $Tag python -c "import sys; print(f'Python {sys.version}')" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Image can run Python commands" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ Image cannot run Python commands" -ForegroundColor Red
        return $false
    }
}

# Build CPU base
Write-Host "=== Building CPU Base ===" -ForegroundColor Yellow
if (-not (Build-BaseImage "CPU" "Dockerfile.builder" "${ImageName}:docker" "CPU Base with TA-Lib and build tools")) {
    Write-Host "❌ CPU base build failed. Exiting." -ForegroundColor Red
    exit 1
}

# Verify CPU base
if (-not (Verify-BaseImage "${ImageName}:docker")) {
    Write-Host "❌ CPU base verification failed. Exiting." -ForegroundColor Red
    exit 1
}

# Build ML base (depends on CPU base)
Write-Host "=== Building ML Base ===" -ForegroundColor Yellow
if (-not (Build-BaseImage "ML" "Dockerfile.ml" "${ImageName}:docker-ml" "ML Base with LangChain, ChromaDB, sentence-transformers")) {
    Write-Host "❌ ML base build failed. Exiting." -ForegroundColor Red
    exit 1
}

# Verify ML base
Write-Host "Verifying ML base packages..." -ForegroundColor Yellow
$MLVerify = docker run --rm "${ImageName}:docker-ml" python -c "import langchain; import chromadb; import sentence_transformers; import ollama; import talib; print('✅ ML packages verified')" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ML base packages verified" -ForegroundColor Green
} else {
    Write-Host "❌ ML base packages verification failed" -ForegroundColor Red
    exit 1
}

# Build GPU base (depends on ML base)
Write-Host "=== Building GPU Base ===" -ForegroundColor Yellow
if (-not (Build-BaseImage "GPU" "Dockerfile.gpu" "${ImageName}:docker-gpu" "GPU Base with PyTorch, Transformers, training libraries")) {
    Write-Host "❌ GPU base build failed. Exiting." -ForegroundColor Red
    exit 1
}

# Verify GPU base
Write-Host "Verifying GPU base packages..." -ForegroundColor Yellow
$GPUVerify = docker run --rm "${ImageName}:docker-gpu" python -c "import torch; import transformers; import stable_baselines3; import gymnasium; print(f'✅ GPU packages verified (PyTorch {torch.__version__})')" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ GPU base packages verified" -ForegroundColor Green
} else {
    Write-Host "❌ GPU base packages verification failed" -ForegroundColor Red
    exit 1
}

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "All Base Images Built Successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Base Images:"
Write-Host "  - ${ImageName}:docker (CPU Base)"
Write-Host "  - ${ImageName}:docker-ml (ML Base)"
Write-Host "  - ${ImageName}:docker-gpu (GPU Base)"
Write-Host ""
Write-Host "Image Sizes:"
docker images "${ImageName}:docker" "${ImageName}:docker-ml" "${ImageName}:docker-gpu" --format "  {{.Repository}}:{{.Tag}} - {{.Size}}"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Test base images with service builds (run test-service-builds.ps1)"
Write-Host "  2. Verify service images work correctly"
Write-Host "  3. Push to DockerHub (if tests pass)"
Write-Host ""


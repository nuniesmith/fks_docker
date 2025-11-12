# Clean up test images after testing (PowerShell)

$ErrorActionPreference = "Stop"

$ImageName = "nuniesmith/fks"
$TestTagSuffix = "-test"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cleaning Up Test Images" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Find test images
Write-Host "Finding test images..." -ForegroundColor Yellow
$TestImages = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String "${ImageName}.*${TestTagSuffix}"

if (-not $TestImages) {
    Write-Host "No test images found" -ForegroundColor Yellow
    exit 0
}

Write-Host "Test images found:"
$TestImages | ForEach-Object { Write-Host "  - $_" }

Write-Host ""

# Ask for confirmation
$Confirm = Read-Host "Do you want to remove these test images? (y/n)"
if ($Confirm -ne "y" -and $Confirm -ne "Y") {
    Write-Host "Cleanup cancelled" -ForegroundColor Yellow
    exit 0
}

# Remove test images
Write-Host "Removing test images..." -ForegroundColor Yellow
$TestImages | ForEach-Object {
    $Image = $_.ToString()
    docker rmi $Image 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Removed: $Image" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to remove: $Image" -ForegroundColor Red
    }
}

Write-Host "✅ Cleanup complete" -ForegroundColor Green


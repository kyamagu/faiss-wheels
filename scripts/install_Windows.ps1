#!/usr/bin/env pwsh
# Requires -Version 5.0
$ErrorActionPreference = "Stop"

function Install-OpenBLAS {
    param (
        [string]$arch
    )
    Write-Host "Installing OpenBLAS for Windows..."
    $OPENBLAS_VERSION = "0.3.30"
    $OPENBLAS_URL = "https://github.com/OpenMathLib/OpenBLAS/releases/download/v$OPENBLAS_VERSION/OpenBLAS-$OPENBLAS_VERSION-$arch.zip"
    $ZIP_PATH = "$env:RUNNER_TEMP\OpenBLAS.zip"
    $INSTALL_DIR = $env:OPENBLAS_DIR
    if (-not $INSTALL_DIR) { $INSTALL_DIR = "C:\Program Files\OpenBLAS" }

    Invoke-WebRequest -Uri $OPENBLAS_URL -OutFile $ZIP_PATH
    New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null

    # Extract to destination
    Expand-Archive -Path $ZIP_PATH -DestinationPath $INSTALL_DIR -Force
    $extracted = Get-ChildItem -Path $INSTALL_DIR -Directory | Where-Object { $_.Name -like "OpenBLAS*" }
    if ($extracted) {
        Move-Item -Path "$($extracted.FullName)\*" -Destination $INSTALL_DIR -Force
        Remove-Item -Path $extracted.FullName -Recurse -Force
    }

    # Set environment variables for GitHub Actions
    Add-Content -Path $env:GITHUB_ENV -Value "PATH=$env:PATH;$INSTALL_DIR\bin"
    Add-Content -Path $env:GITHUB_ENV -Value "CPATH=$env:CPATH;$INSTALL_DIR\include"
    Add-Content -Path $env:GITHUB_ENV -Value "LIB=$env:LIB;$INSTALL_DIR\lib"
}

# Install system dependencies
if ($env:PROCESSOR_IDENTIFIER -like "ARM*") {
    # NOTE: PROCESSOR_ARCHITECTURE is incorrectly set to "AMD64" on emulated ARM64 Windows runners.
    Install-OpenBLAS -arch "woa64-dll"
} else {
    Install-OpenBLAS -arch "x64"
}
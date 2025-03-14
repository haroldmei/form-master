# Script to build and publish the Form-Master package to PyPI

# Ensure we have the latest pip, setuptools, wheel, and twine
Write-Host "Installing/upgrading build tools..."
python -m pip install --upgrade pip setuptools wheel twine build

# Clean up any existing builds
if (Test-Path "dist") {
    Remove-Item -Path "dist" -Recurse -Force
}
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}
if (Test-Path "form_master.egg-info") {
    Remove-Item -Path "form_master.egg-info" -Recurse -Force
}

# Build the package
Write-Host "Building package..."
python -m build

# Check if build was successful
if (-not (Test-Path "dist")) {
    Write-Host "Build failed! No dist directory found." -ForegroundColor Red
    exit 1
}

# Ask if we should upload to TestPyPI first
$testPyPI = Read-Host "Upload to TestPyPI first for testing? (y/n)"
if ($testPyPI -eq "y") {
    Write-Host "Uploading to TestPyPI..."
    python -m twine upload --repository testpypi dist/* --verbose
    
    # Provide instructions for testing
    Write-Host "`nTo test the package from TestPyPI, run:" -ForegroundColor Green
    Write-Host "pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple form-master`n" -ForegroundColor Cyan
}

# Ask to upload to real PyPI
$uploadPyPI = Read-Host "Upload to PyPI? (y/n)"
if ($uploadPyPI -eq "y") {
    # Check if API token is available
    $pypiToken = $env:PYPI_API_TOKEN
    if (-not $pypiToken) {
        Write-Host "No PyPI API token found in environment variable PYPI_API_TOKEN" -ForegroundColor Yellow
        Write-Host "You will be prompted to enter PyPI credentials" -ForegroundColor Yellow
    }
    
    Write-Host "Uploading to PyPI..."
    python -m twine upload dist/* --verbose
    
    Write-Host "`nPackage published to PyPI successfully!" -ForegroundColor Green
    Write-Host "Users can now install with: pip install form-master" -ForegroundColor Cyan
} else {
    Write-Host "Skipped uploading to PyPI" -ForegroundColor Yellow
}

Write-Host "`nBuild and publish process complete!" -ForegroundColor Green

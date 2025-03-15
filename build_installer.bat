@echo off
echo Building Form-Master Installer...

rem Create build directory if it doesn't exist
if not exist build mkdir build

rem Find NSIS
set NSIS_PATH="C:\Program Files (x86)\NSIS\makensis.exe"
if not exist %NSIS_PATH% (
    set NSIS_PATH="C:\Program Files\NSIS\makensis.exe"
)

if not exist %NSIS_PATH% (
    echo ERROR: NSIS not found. Please install NSIS first.
    echo Download from: https://nsis.sourceforge.io/Download
    exit /b 1
)

rem Download Python installer if needed
set PYTHON_VERSION=3.11.4
set PYTHON_INSTALLER=python-%PYTHON_VERSION%-amd64.exe
if not exist "build\%PYTHON_INSTALLER%" (
    echo Downloading Python %PYTHON_VERSION% installer...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/%PYTHON_VERSION%/%PYTHON_INSTALLER%' -OutFile 'build\%PYTHON_INSTALLER%'}"
    if %ERRORLEVEL% neq 0 (
        echo Failed to download Python installer.
        echo The installer will try to download it during installation.
    )
)

rem Build the Python package
echo Building Python package...
python -m pip install --upgrade build
python -m build
if %ERRORLEVEL% neq 0 (
    echo WARNING: Python package build failed. The installer will use PyPI or build from source.
) else (
    echo Python package build successful.
)

rem Create installer using NSIS
echo Building installer with NSIS...
%NSIS_PATH% formmaster_installer.nsi
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to build installer. Check NSIS output for details.
    exit /b 1
)

echo Form-Master installer build completed successfully.
echo Installer location: build\Form-Master-Setup.exe

pause

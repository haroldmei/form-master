@echo off
echo Building Form-Master installer (simple version)...

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

rem Get NSIS directory path (simpler approach)
for /f "tokens=*" %%a in ('echo %NSIS_PATH%') do (
    set NSIS_FULL=%%~a
)
set NSIS_DIR=%NSIS_FULL:"=%
set NSIS_DIR=%NSIS_DIR:makensis.exe=%

rem Check if Python is installed
python --version >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Python not found. Python is required to download dependencies.
    exit /b 1
)

rem Create build directory structure
if not exist build mkdir build
if not exist build\packages mkdir build\packages
if not exist build\drivers mkdir build\drivers
if not exist build\drivers\chromedriver mkdir build\drivers\chromedriver
if not exist build\drivers\geckodriver mkdir build\drivers\geckodriver

rem Download Python installer
echo Downloading Python installer...
set PYTHON_VERSION=3.11.1
set PYTHON_INSTALLER=python-%PYTHON_VERSION%-amd64.exe
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/%PYTHON_INSTALLER%

if not exist "build\%PYTHON_INSTALLER%" (
    echo Downloading Python %PYTHON_VERSION% installer...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile 'build\%PYTHON_INSTALLER%'}"
)

rem Download dependencies
echo Downloading Python dependencies...
python -m pip install --upgrade pip wheel
python -m pip download -r src\requirements.txt -d build\packages --only-binary=:all:
python -m pip download webdriver-manager -d build\packages --only-binary=:all:
python -m pip download wheel setuptools pip -d build\packages

rem Download WebDrivers
echo Downloading WebDrivers...
if not exist "build\drivers\chromedriver\chromedriver.exe" (
    echo Please download ChromeDriver manually from https://chromedriver.chromium.org/downloads
    echo and place chromedriver.exe in build\drivers\chromedriver\
)
if not exist "build\drivers\geckodriver\geckodriver.exe" (
    echo Please download GeckoDriver manually from https://github.com/mozilla/geckodriver/releases
    echo and place geckodriver.exe in build\drivers\geckodriver\
)

rem Create icon file for context menu if it doesn't exist
if not exist "build\formmaster.ico" (
    echo Creating Form-Master icon...
    powershell -Command "& {Add-Type -AssemblyName System.Drawing; $icon = New-Object System.Drawing.Bitmap 32, 32; $g = [System.Drawing.Graphics]::FromImage($icon); $g.Clear([System.Drawing.Color]::FromArgb(0, 120, 215)); $font = New-Object System.Drawing.Font('Arial', 16, [System.Drawing.FontStyle]::Bold); $g.DrawString('FM', $font, [System.Drawing.Brushes]::White, 2, 4); $icon.Save('build\formmaster.ico', [System.Drawing.Imaging.ImageFormat]::Icon); $g.Dispose(); $icon.Dispose();}"
    if %ERRORLEVEL% neq 0 (
        echo Failed to create icon file. Using default NSIS icon.
        copy "%NSIS_DIR%Contrib\Graphics\Icons\modern-install.ico" "build\formmaster.ico"
        if %ERRORLEVEL% neq 0 (
            echo Could not copy default icon. Will proceed without an icon.
        )
    )
)

rem Build the installer using the simple script
echo Building installer...
%NSIS_PATH% simple_installer.nsi

echo Done!
if exist Form-Master-Setup.exe (
    echo Installer created: Form-Master-Setup.exe
) else (
    echo Error: Installer not created.
)

pause

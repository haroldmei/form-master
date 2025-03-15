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
set PYTHON_VERSION=3.9.13
set PYTHON_INSTALLER=python-%PYTHON_VERSION%-amd64.exe
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/%PYTHON_INSTALLER%

if not exist "build\%PYTHON_INSTALLER%" (
    echo Downloading Python %PYTHON_VERSION% installer...
    powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile 'build\%PYTHON_INSTALLER%'}"
)

rem Download ALL Python dependencies including nested dependencies
echo Downloading ALL Python dependencies with recursive resolution...
python -m pip install --upgrade pip wheel
echo Creating a complete requirements list...

rem Create a temporary requirements file with specific versions
python -c "import pkg_resources; open('full_requirements.txt', 'w').write('\n'.join(['=='.join([d.project_name, d.version]) for d in pkg_resources.working_set if d.project_name.lower() in ['selenium', 'pandas', 'pynput', 'python-docx', 'fire', 'wheel', 'setuptools', 'pip']]))"

rem Add all specific requirements
echo Adding all requirements from requirements.txt with versions...
python -c "import pkg_resources; reqs = [line.strip() for line in open('src/requirements.txt') if line.strip() and not line.startswith('#')]; open('full_requirements.txt', 'a').write('\n' + '\n'.join(reqs))"

type full_requirements.txt

rem Download all specified packages with their dependencies
echo Downloading all packages with dependencies...
python -m pip download -r full_requirements.txt -d build\packages --only-binary=:all:

rem Download additional required packages
echo Downloading additional utility packages...
python -m pip download webdriver-manager urllib3 certifi -d build\packages --only-binary=:all:

rem Special handling for critical packages - ensure they're properly downloaded
echo Ensuring critical packages are downloaded...
python -m pip download selenium==4.10.0 -d build\packages --only-binary=:all:
python -m pip download pynput==1.7.6 -d build\packages --only-binary=:all:
python -m pip download pandas==1.5.3 -d build\packages --only-binary=:all:
python -m pip download python-docx==0.8.11 -d build\packages --only-binary=:all:
python -m pip download fire==0.5.0 -d build\packages --only-binary=:all:

rem Download all pynput dependencies explicitly
echo Downloading pynput dependencies...
python -m pip download six pywin32 pyobjc-core pyobjc-framework-Quartz -d build\packages --only-binary=:all:

rem Verify critical packages were downloaded successfully
echo Verifying critical packages...
for %%p in (selenium pynput pandas python-docx fire) do (
    dir build\packages\%%p* >nul 2>nul
    if %ERRORLEVEL% neq 0 (
        echo CRITICAL ERROR: Package %%p not found after download attempt!
        echo Attempting emergency download directly...
        python -m pip download %%p --no-deps -d build\packages
    )
)

rem Test importing packages to ensure they work
echo Testing package imports...
python -c "import selenium, pandas; print('Selenium and pandas import successful')"
python -c "import pynput; print('Pynput import successful')" || (
    echo WARNING: Pynput not installed or not working in the build environment.
    echo Installing pynput in build environment for testing...
    python -m pip install pynput
    python -c "import pynput; print('Pynput now installed')"
)

rem Cleanup temporary file
del full_requirements.txt

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
if exist build\Form-Master-Setup.exe (
    echo Installer created: build\Form-Master-Setup.exe
) else (
    echo Error: Installer not created.
)

rem Optional: Copy to root directory for convenience
copy build\Form-Master-Setup.exe Form-Master-Setup.exe >nul 2>nul
if %ERRORLEVEL% == 0 (
    echo Installer also copied to: Form-Master-Setup.exe
)

pause

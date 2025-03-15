@echo off
echo Building Form-Master installer...
echo.

rem Check if NSIS is installed
where makensis >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo NSIS not found. Please install NSIS from https://nsis.sourceforge.io/Download
    echo After installation, make sure "makensis.exe" is in your PATH.
    echo.
    echo Press any key to open the NSIS download page...
    pause >nul
    start https://nsis.sourceforge.io/Download
    exit /b 1
)

rem Check if Python is installed
python --version >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Python not found. Python is required to download dependencies.
    exit /b 1
)

rem Create directories
echo Creating build directories...
if not exist build mkdir build
if not exist build\dependencies mkdir build\dependencies
if not exist build\packages mkdir build\packages
if not exist build\drivers mkdir build\drivers
if not exist build\drivers\chromedriver mkdir build\drivers\chromedriver

rem Download Python installer
echo Downloading Python installer...
set PYTHON_VERSION=3.11.1
set PYTHON_INSTALLER=python-%PYTHON_VERSION%-amd64.exe
set PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/%PYTHON_INSTALLER%

if not exist "build\%PYTHON_INSTALLER%" (
    echo Downloading Python %PYTHON_VERSION% installer...
    curl -L "%PYTHON_URL%" -o "build\%PYTHON_INSTALLER%"
    if %ERRORLEVEL% neq 0 (
        echo Failed to download Python installer. Trying with PowerShell...
        powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile 'build\%PYTHON_INSTALLER%'}"
        if %ERRORLEVEL% neq 0 (
            echo Failed to download Python installer! Please download manually from:
            echo %PYTHON_URL%
            echo And place it in the build directory as %PYTHON_INSTALLER%
            exit /b 1
        )
    )
)

rem Download Chrome WebDriver
echo Downloading Chrome WebDriver...
set CHROMEDRIVER_VERSION=114.0.5735.90
set CHROMEDRIVER_URL=https://chromedriver.storage.googleapis.com/%CHROMEDRIVER_VERSION%/chromedriver_win32.zip
set CHROMEDRIVER_ZIP=build\drivers\chromedriver_win32.zip

if not exist "%CHROMEDRIVER_ZIP%" (
    echo Downloading Chrome WebDriver %CHROMEDRIVER_VERSION%...
    curl -L "%CHROMEDRIVER_URL%" -o "%CHROMEDRIVER_ZIP%"
    if %ERRORLEVEL% neq 0 (
        echo Failed to download Chrome WebDriver. Trying with PowerShell...
        powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%CHROMEDRIVER_URL%' -OutFile '%CHROMEDRIVER_ZIP%'}"
        if %ERRORLEVEL% neq 0 (
            echo Failed to download Chrome WebDriver! Please download manually from:
            echo %CHROMEDRIVER_URL%
            echo And place it in the build\drivers directory
            exit /b 1
        )
    )
    
    echo Extracting Chrome WebDriver...
    powershell -Command "Expand-Archive -Path '%CHROMEDRIVER_ZIP%' -DestinationPath 'build\drivers\chromedriver' -Force"
)

rem Download Gecko (Firefox) WebDriver
echo Downloading Firefox WebDriver...
set GECKODRIVER_VERSION=v0.33.0
set GECKODRIVER_URL=https://github.com/mozilla/geckodriver/releases/download/%GECKODRIVER_VERSION%/geckodriver-v0.33.0-win64.zip
set GECKODRIVER_ZIP=build\drivers\geckodriver-win64.zip

if not exist "%GECKODRIVER_ZIP%" (
    echo Downloading Firefox WebDriver %GECKODRIVER_VERSION%...
    curl -L "%GECKODRIVER_URL%" -o "%GECKODRIVER_ZIP%"
    if %ERRORLEVEL% neq 0 (
        echo Failed to download Firefox WebDriver. Trying with PowerShell...
        powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%GECKODRIVER_URL%' -OutFile '%GECKODRIVER_ZIP%'}"
        if %ERRORLEVEL% neq 0 (
            echo Failed to download Firefox WebDriver! Please download manually from:
            echo %GECKODRIVER_URL%
            echo And place it in the build\drivers directory
            exit /b 1
        )
    )
    
    echo Extracting Firefox WebDriver...
    if not exist build\drivers\geckodriver mkdir build\drivers\geckodriver
    powershell -Command "Expand-Archive -Path '%GECKODRIVER_ZIP%' -DestinationPath 'build\drivers\geckodriver' -Force"
)

rem Download Python packages using wheels (no compilation needed)
echo Downloading Python dependencies...
python -m pip install --upgrade pip
python -m pip install wheel

rem Download binary wheels for all dependencies
echo Downloading binary wheels for dependencies...
python -m pip download -r src\requirements.txt -d build\packages --only-binary=:all:
python -m pip download webdriver-manager -d build\packages --only-binary=:all:

rem Download pip, wheel, setuptools
python -m pip download wheel -d build\packages
python -m pip download setuptools -d build\packages
python -m pip download pip -d build\packages

rem Ensure context.reg.template is present and up-to-date
echo Checking for context.reg.template...
if not exist "context.reg.template" (
    echo Creating context.reg.template...
    (
        echo Windows Registry Editor Version 5.00
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster]
        echo @="Form-Master"
        echo "Icon"="PYTHON_PATH"
        echo "SubCommands"=""
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\general]
        echo @="General Form-Master"
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\general\command] 
        echo @="\"PYTHON_PATH\" -m formfiller \"%%V\""
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\usyd]
        echo @="Sydney University Application"
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\usyd\command]
        echo @="\"PYTHON_PATH\" -m formfiller --uni=usyd \"%%V\""
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\unsw]
        echo @="New South Wales University Application"
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\Background\shell\FormMaster\shell\unsw\command]
        echo @="\"PYTHON_PATH\" -m formfiller --uni=unsw \"%%V\""
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\shell\FormMaster]
        echo @="Process with Form-Master"
        echo "Icon"="PYTHON_PATH"
        echo "SubCommands"=""
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\general]
        echo @="General Form-Master"
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\general\command]
        echo @="\"PYTHON_PATH\" -m formfiller \"%%1\""
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\usyd]
        echo @="Sydney University Application"
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\usyd\command]
        echo @="\"PYTHON_PATH\" -m formfiller --uni=usyd \"%%1\""
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\unsw]
        echo @="New South Wales University Application"
        echo.
        echo [HKEY_CLASSES_ROOT\Directory\shell\FormMaster\shell\unsw\command]
        echo @="\"PYTHON_PATH\" -m formfiller --uni=unsw \"%%1\""
    ) > context.reg.template
)

rem Build the installer using the simple script (more reliable)
echo Running NSIS compiler with simple installer script...
makensis simple_installer.nsi

if %ERRORLEVEL% neq 0 (
    echo.
    echo Compilation with simple_installer.nsi failed. Trying alternative approach...
    
    rem Try to build using installer-fixed.bat
    call installer-fixed.bat
    
    if %ERRORLEVEL% neq 0 (
        echo.
        echo All compilation attempts failed. Please check NSIS installation and script files.
        exit /b 1
    )
)

echo.
echo Installer built successfully: Form-Master-Setup.exe
echo.
echo Press any key to exit...
pause >nul

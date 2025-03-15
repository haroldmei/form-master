@echo off
echo Running NSIS compiler with fixed installer script...

set NSIS_PATH="C:\Program Files (x86)\NSIS\makensis.exe"
if not exist %NSIS_PATH% (
    set NSIS_PATH="C:\Program Files\NSIS\makensis.exe"
)

if not exist %NSIS_PATH% (
    echo ERROR: NSIS not found. Please install NSIS first.
    echo Download from: https://nsis.sourceforge.io/Download
    exit /b 1
)

echo Compiling installer script...
%NSIS_PATH% installer.nsi

if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: NSIS compilation failed!
    echo Check for syntax errors in the installer.nsi file.
    exit /b 1
)

echo.
echo Installer compiled successfully! The output file is Form-Master-Setup.exe
echo.
pause

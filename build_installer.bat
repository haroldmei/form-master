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

rem Build the installer
echo Running NSIS compiler...
makensis installer.nsi

if %ERRORLEVEL% neq 0 (
    echo.
    echo Compilation failed. Please check for errors in the installer script.
    exit /b 1
)

echo.
echo Installer built successfully: Form-Master-Setup.exe
echo.
echo Press any key to exit...
pause >nul

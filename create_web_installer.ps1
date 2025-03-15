# Script to create a web installer for Form-Master
# This script creates an NSIS installer that will download and install Python and Form-Master

# Configuration
$python_version = "3.11.1"
$python_url = "https://www.python.org/ftp/python/$python_version/python-$python_version-amd64.exe"
$nsis_url = "https://sourceforge.net/projects/nsis/files/NSIS%203/3.09/nsis-3.09-setup.exe/download"
$output_exe = "web_setup.exe"

# Create build directory
$build_dir = Join-Path $PSScriptRoot "build"
if (!(Test-Path $build_dir)) {
    New-Item -ItemType Directory -Path $build_dir | Out-Null
}

# Check for NSIS installation in standard and custom locations
function Find-NSIS {
    $standard_paths = @(
        "C:\Program Files (x86)\NSIS\makensis.exe",
        "C:\Program Files\NSIS\makensis.exe",
        "$env:ProgramFiles\NSIS\makensis.exe",
        "$env:ProgramFiles (x86)\NSIS\makensis.exe"
    )
    
    foreach ($path in $standard_paths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Check if NSIS is in PATH
    $nsis_in_path = Get-Command "makensis.exe" -ErrorAction SilentlyContinue
    if ($nsis_in_path) {
        return $nsis_in_path.Path
    }
    
    return $null
}

$nsis_path = Find-NSIS

# If NSIS is not found, attempt to install it or ask for manual installation
if (!$nsis_path) {
    Write-Host "NSIS not found on this system." -ForegroundColor Yellow
    
    $install_choice = Read-Host "Would you like to attempt automatic installation of NSIS? (y/n)"
    if ($install_choice -eq "y") {
        try {
            Write-Host "Downloading NSIS installer..."
            $nsis_installer = Join-Path $build_dir "nsis_installer.exe"
            Invoke-WebRequest -Uri $nsis_url -OutFile $nsis_installer -UseBasicParsing
            
            Write-Host "Installing NSIS silently..."
            Start-Process -FilePath $nsis_installer -ArgumentList "/S" -Wait -NoNewWindow
            
            # Check if installation was successful
            $nsis_path = Find-NSIS
            if ($nsis_path) {
                Write-Host "NSIS installed successfully at: $nsis_path" -ForegroundColor Green
                Remove-Item $nsis_installer -Force
            } else {
                throw "NSIS not found after installation attempt."
            }
        }
        catch {
            Write-Host "Automatic NSIS installation failed: $_" -ForegroundColor Red
            $manual_steps = $true
        }
    } else {
        $manual_steps = $true
    }
    
    # If automatic installation failed or was declined, provide manual steps
    if ($manual_steps -or !$nsis_path) {
        Write-Host "`n==== MANUAL NSIS INSTALLATION REQUIRED ====`n" -ForegroundColor Yellow
        Write-Host "Please follow these steps to install NSIS manually:"
        Write-Host "1. Download NSIS from: https://nsis.sourceforge.io/Download" -ForegroundColor Cyan
        Write-Host "2. Run the installer and follow the installation wizard"
        Write-Host "3. After installation, you can either:"
        Write-Host "   a. Run this script again, or" 
        Write-Host "   b. Enter the path to makensis.exe below"
        
        $custom_nsis_path = Read-Host "`nEnter the full path to makensis.exe (or press Enter to exit)"
        if ($custom_nsis_path -and (Test-Path $custom_nsis_path)) {
            $nsis_path = $custom_nsis_path
            Write-Host "Using custom NSIS path: $nsis_path" -ForegroundColor Green
        } else {
            Write-Host "Script cannot continue without NSIS. Exiting..." -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host "Using NSIS from: $nsis_path" -ForegroundColor Green

# Create resources directory for installer files
$resources_dir = Join-Path $build_dir "resources"
if (!(Test-Path $resources_dir)) {
    New-Item -ItemType Directory -Path $resources_dir | Out-Null
}

# Copy important project files to resources
Write-Host "Copying project files to build directory..."
Copy-Item -Path (Join-Path $PSScriptRoot "README.md") -Destination $resources_dir -Force
Copy-Item -Path (Join-Path $PSScriptRoot "setup.py") -Destination $resources_dir -Force
if (Test-Path (Join-Path $PSScriptRoot "src")) {
    Copy-Item -Path (Join-Path $PSScriptRoot "src") -Destination $resources_dir -Recurse -Force
} else {
    Write-Host "Warning: 'src' directory not found. Make sure your project structure is correct." -ForegroundColor Yellow
}

# Create installer script
$nsi_script = @"
; Form-Master Web Installer Script
Unicode true

!define APPNAME "Form-Master"
!define DESCRIPTION "Form automation tool for Australian university applications"
!define VERSION "0.1.0"
!define PYTHON_URL "$python_url"
!define PYTHON_INSTALLER "python-$python_version-amd64.exe"

Name "\${APPNAME} \${VERSION}"
OutFile "$output_exe"
InstallDir "\$PROGRAMFILES64\Form-Master"
InstallDirRegKey HKLM "Software\Form-Master" "Install_Dir"
RequestExecutionLevel admin

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!include "WinMessages.nsh"

; Modern UI settings
!define MUI_ABORTWARNING
!define MUI_ICON "\${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_UNICON "\${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "\${NSISDIR}\Contrib\Graphics\Wizard\win.bmp"

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Launch Form-Master Now"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchApplication"

Function LaunchApplication
  ExecShell "" "\$SMPROGRAMS\Form-Master\Form-Master.lnk"
FunctionEnd

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "resources\README.md"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; Show details by default
ShowInstDetails show
ShowUninstDetails show

; Installer sections
Section "Python 3.11.1 (Required)" SectionPython
    SectionIn RO  ; Read-only, cannot be deselected
    SetOutPath "\$TEMP"
    
    ; Check if Python is already installed
    ReadRegStr \$0 HKLM "Software\Python\PythonCore\3.11\InstallPath" ""
    ReadRegStr \$1 HKCU "Software\Python\PythonCore\3.11\InstallPath" ""
    
    ${If} \$0 != ""
    ${OrIf} \$1 != ""
        DetailPrint "Python 3.11 is already installed."
    ${Else}
        DetailPrint "Downloading Python..."
        inetc::get "\${PYTHON_URL}" "\$TEMP\\${PYTHON_INSTALLER}" /POPUP
        Pop \$0
        ${If} \$0 != "OK"
            DetailPrint "Python download failed: \$0"
            MessageBox MB_ICONEXCLAMATION|MB_OK "Failed to download Python. Please check your internet connection and try again."
            Abort "Failed to download Python."
        ${EndIf}
        
        DetailPrint "Installing Python..."
        ExecWait '"\$TEMP\\${PYTHON_INSTALLER}" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0'
        Delete "\$TEMP\\${PYTHON_INSTALLER}"
    ${EndIf}
    
    ; Verify Python installation
    ClearErrors
    ExecWait 'python --version' \$0
    ${If} \$0 != 0
        MessageBox MB_ICONEXCLAMATION|MB_OK "Python installation verification failed. You may need to install Python 3.11 manually."
    ${EndIf}
SectionEnd

Section "Form-Master" SectionFormMaster
    SectionIn RO  ; Read-only, cannot be deselected
    SetOutPath "\$INSTDIR"
    
    ; Create directory structure
    CreateDirectory "\$INSTDIR\src"
    
    ; Copy files
    File /r "resources\*.*"
    
    ; Install Form-Master using pip
    DetailPrint "Installing Form-Master and dependencies..."
    DetailPrint "Upgrading pip..."
    nsExec::ExecToLog 'python -m pip install --upgrade pip'
    DetailPrint "Installing wheel..."
    nsExec::ExecToLog 'python -m pip install wheel'
    DetailPrint "Installing form-master from local directory..."
    nsExec::ExecToLog 'python -m pip install -e "\$INSTDIR"'
    
    ; Create shortcuts
    CreateDirectory "\$SMPROGRAMS\Form-Master"
    CreateShortcut "\$SMPROGRAMS\Form-Master\Form-Master.lnk" "cmd.exe" '/k python -m formmaster.formfiller' "\$INSTDIR\resources\icon.ico"
    CreateShortcut "\$SMPROGRAMS\Form-Master\Uninstall.lnk" "\$INSTDIR\uninstall.exe"
    CreateShortcut "\$DESKTOP\Form-Master.lnk" "cmd.exe" '/k python -m formmaster.formfiller' "\$INSTDIR\resources\icon.ico"
    
    ; Create uninstaller
    WriteUninstaller "\$INSTDIR\uninstall.exe"
    
    ; Write registry keys for uninstall
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "DisplayName" "Form-Master"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "UninstallString" '"\$INSTDIR\uninstall.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "DisplayVersion" "\${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master" "Publisher" "Form-Master Team"
    WriteRegStr HKLM "Software\Form-Master" "Install_Dir" "\$INSTDIR"
SectionEnd

Section "Install Browser Drivers (Chrome, Firefox)" SectionDrivers
    SetOutPath "\$INSTDIR\drivers"
    
    DetailPrint "Installing WebDriver Manager..."
    nsExec::ExecToLog 'python -m pip install webdriver-manager'
    
    DetailPrint "Installing WebDriver for Chrome..."
    nsExec::ExecToLog 'python -c "from webdriver_manager.chrome import ChromeDriverManager; ChromeDriverManager().install()"'
    
    DetailPrint "Installing WebDriver for Firefox..."
    nsExec::ExecToLog 'python -c "from webdriver_manager.firefox import GeckoDriverManager; GeckoDriverManager().install()"'
SectionEnd

; Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT \${SectionPython} "Installs Python 3.11.1, required to run Form-Master."
    !insertmacro MUI_DESCRIPTION_TEXT \${SectionFormMaster} "Installs the Form-Master application."
    !insertmacro MUI_DESCRIPTION_TEXT \${SectionDrivers} "Installs browser drivers required for web automation."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Uninstaller section
Section "Uninstall"
    ; Display a message
    DetailPrint "Uninstalling Form-Master..."
    
    ; Uninstall Form-Master package
    DetailPrint "Removing Python package..."
    nsExec::ExecToLog 'python -m pip uninstall -y form-master'
    
    ; Remove directories and files
    DetailPrint "Removing installed files..."
    RMDir /r "\$INSTDIR\src"
    Delete "\$INSTDIR\setup.py"
    Delete "\$INSTDIR\README.md"
    Delete "\$INSTDIR\uninstall.exe"
    RMDir /r "\$INSTDIR"
    
    ; Remove shortcuts
    DetailPrint "Removing shortcuts..."
    Delete "\$SMPROGRAMS\Form-Master\Form-Master.lnk"
    Delete "\$SMPROGRAMS\Form-Master\Uninstall.lnk"
    RMDir "\$SMPROGRAMS\Form-Master"
    Delete "\$DESKTOP\Form-Master.lnk"
    
    ; Remove registry keys
    DetailPrint "Removing registry entries..."
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Form-Master"
    DeleteRegKey HKLM "Software\Form-Master"
    
    DetailPrint "Uninstallation complete."
SectionEnd
"@

# Generate icon for the installer
$icon_path = Join-Path $resources_dir "icon.ico"
if (!(Test-Path $icon_path)) {
    Write-Host "Generating application icon..."
    try {
        # Create a simple icon using .NET
        Add-Type -AssemblyName System.Drawing
        $icon = New-Object System.Drawing.Bitmap 32, 32
        $graphics = [System.Drawing.Graphics]::FromImage($icon)
        $graphics.FillRectangle((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0, 120, 215))), 0, 0, 32, 32)
        $graphics.DrawString("FM", (New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::White, 2, 4)
        $icon.Save($icon_path, [System.Drawing.Imaging.ImageFormat]::Icon)
        $graphics.Dispose()
        $icon.Dispose()
    }
    catch {
        Write-Host "Failed to generate icon: $_" -ForegroundColor Yellow
        Write-Host "Using default icon." -ForegroundColor Yellow
    }
}

# Write the NSIS script to a file
$nsi_file = Join-Path $build_dir "installer.nsi"
Set-Content -Path $nsi_file -Value $nsi_script

# Check if additional NSIS plugins are needed
$plugin_check = Select-String -Path $nsi_file -Pattern "inetc::|nsExec::"
if ($plugin_check) {
    # NSIS simple service plugin is needed for nsExec
    $plugins_dir = Split-Path $nsis_path -Parent
    $plugins_dir = Join-Path $plugins_dir "Plugins"
    $plugins_x86_dir = Join-Path $plugins_dir "x86-ansi"
    
    if (!(Test-Path (Join-Path $plugins_x86_dir "inetc.dll"))) {
        Write-Host "The installer script uses the 'inetc' plugin which may not be installed." -ForegroundColor Yellow
        Write-Host "If the compilation fails, please install the NSIS InetC plugin from:" -ForegroundColor Yellow
        Write-Host "https://nsis.sourceforge.io/Inetc_plug-in" -ForegroundColor Cyan
    }
}

# Compile the NSIS script
Write-Host "`nCreating installer..." -ForegroundColor Green
try {
    $process = Start-Process -FilePath $nsis_path -ArgumentList $nsi_file -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -ne 0) {
        throw "NSIS returned error code: $($process.ExitCode)"
    }
    
    # Move the installer to the root directory
    $final_output = Join-Path $PSScriptRoot $output_exe
    if (Test-Path $final_output) {
        Remove-Item $final_output -Force
    }
    
    $created_installer = Join-Path $PSScriptRoot $output_exe
    if (Test-Path $created_installer) {
        Move-Item -Path $created_installer -Destination $final_output -Force
        Write-Host "`nWeb installer created successfully: $final_output" -ForegroundColor Green
        Write-Host "This installer will download and install Python $python_version if needed, then install Form-Master."
    } else {
        throw "Installer file was not created at the expected location."
    }
} 
catch {
    Write-Host "`nFailed to create installer: $_" -ForegroundColor Red
    Write-Host "`nTroubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "1. Make sure NSIS is properly installed" 
    Write-Host "2. If the error mentions missing plugins, install the required NSIS plugins:"
    Write-Host "   - InetC Plugin: https://nsis.sourceforge.io/Inetc_plug-in"
    Write-Host "3. Try running makensis.exe directly with the script file:"
    Write-Host "   `"$nsis_path`" `"$nsi_file`""
    Write-Host "4. Check the NSIS documentation for any syntax errors: https://nsis.sourceforge.io/Docs/"
    
    Write-Host "`nIf you continue to experience issues, you can create the installer manually:" -ForegroundColor Yellow
    Write-Host "1. Open NSIS (Nullsoft Scriptable Install System)" 
    Write-Host "2. Select 'Compile NSI scripts'" 
    Write-Host "3. Browse to: $nsi_file"
    Write-Host "4. Click 'Compile' to generate the installer"
}

# Optional: Clean up build directory
$cleanup = Read-Host "`nClean up build directory? (y/n)"
if ($cleanup -eq "y") {
    Remove-Item -Path $build_dir -Recurse -Force
    Write-Host "Build directory cleaned up." -ForegroundColor Green
} else {
    Write-Host "Build files remain in: $build_dir" -ForegroundColor Cyan
    Write-Host "You can manually delete this directory if needed."
}
